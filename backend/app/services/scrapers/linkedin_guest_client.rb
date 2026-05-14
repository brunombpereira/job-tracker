module Scrapers
  # LinkedIn jobs scraper using the unauthenticated SSR endpoint that
  # powers the public job-listings preview shown to logged-out visitors:
  #   /jobs-guest/jobs/api/seeMoreJobPostings/search
  #
  # Each request returns ~40 job-card HTML fragments. To pull more than
  # one screen's worth we paginate via the `start` offset (LinkedIn's
  # UI increments by 25 — we use 25 too so overlap-induced dedup is
  # negligible). Pages stop early when the response is empty or when
  # the page yields no new URLs we haven't already seen.
  class LinkedinGuestClient < BaseClient
    SOURCE_NAME  = "linkedin"
    SOURCE_COLOR = "#0a66c2"

    ENDPOINT   = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"
    # The guest endpoint returns ~10 unique cards per request and
    # increments by 25 in the UI. We bump start by 25 each call and
    # let the URL-dedup guard catch the few overlapping cards.
    PAGE_SIZE  = 25
    MAX_PAGES  = 12
    PAGE_DELAY = 0.7

    # Time-posted filter codes that LinkedIn understands (`f_TPR`).
    TIME_FILTERS = {
      "day"   => "r86400",
      "week"  => "r604800",
      "month" => "r2592000"
    }.freeze

    # `keywords` accepts a single string or an array of strings — each is
    # run as its own search and the results are unioned (deduped by URL).
    # Several narrow queries beat one broad "developer" search: the guest
    # API has no profile awareness, so the query string is the only lever
    # on relevance. When no keywords are passed they come from the user's
    # Profile (Settings page), falling back to a bare "developer" search.
    def fetch_raw(params)
      pages    = (params[:pages] || 4).to_i.clamp(1, MAX_PAGES)
      queries  = Array(params[:keywords]).filter_map { |k| k.to_s.strip.presence }
      queries  = profile_keywords if queries.empty?
      queries  = [ "developer" ] if queries.empty?
      # Optional — when no location is given the guest endpoint searches
      # everywhere rather than being pinned to one country.
      location = params[:location].to_s.presence
      time     = TIME_FILTERS[params[:time].to_s] # nil = any
      start_at = params[:start].to_i

      @seen = Set.new
      cards = []
      queries.each_with_index do |query, qi|
        cards.concat(collect_query(query, location, time, start_at, pages))
        polite_sleep(PAGE_DELAY) if qi < queries.size - 1
      end
      cards
    rescue Faraday::Error => e
      raise FetchError, "LinkedIn fetch failed: #{e.message}"
    end

    def normalize(raw)
      {
        title:       raw[:title],
        company:     raw[:company] || "Unknown",
        location:    raw[:location],
        modality:    infer_modality(raw),
        url:         raw[:url],
        description: nil, # not in the listing fragment; user clicks through to the job page
        posted_date: raw[:posted_date],
        stack:       [],
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    def profile_keywords
      Profile.current.linkedin_keywords.filter_map { |k| k.to_s.strip.presence }
    end

    # Paginate one keyword query, returning its newly-seen cards. The
    # shared @seen set means a job surfaced by more than one query is
    # kept once.
    def collect_query(query, location, time, start_at, pages)
      collected = []
      pages.times do |i|
        offset = start_at + i * PAGE_SIZE
        page_cards = fetch_page(query, location, time, offset)
        break if page_cards.empty?

        new_in_page = 0
        page_cards.each do |card|
          attrs = extract(card)
          next unless attrs
          next if @seen.include?(attrs[:url])

          @seen << attrs[:url]
          collected << attrs
          new_in_page += 1
        end
        break if new_in_page.zero?

        polite_sleep(PAGE_DELAY) if i < pages - 1
      end
      collected
    end

    def fetch_page(keywords, location, time, offset)
      res = Faraday.get(ENDPOINT) do |r|
        r.options.timeout = 25
        r.headers["User-Agent"]      = browser_ua
        r.headers["Accept"]          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        r.headers["Accept-Language"] = "en-US,en;q=0.9,pt;q=0.8"
        r.params["keywords"] = keywords
        r.params["location"] = location if location
        r.params["start"]    = offset if offset.positive?
        r.params["f_TPR"]    = time   if time
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      doc = Nokogiri::HTML(res.body)
      doc.css("li > div.base-search-card, div.base-card.base-search-card")
    end

    def extract(card)
      url   = card.at_css("a.base-card__full-link")&.[]("href")
      title = card.at_css(".base-search-card__title")&.text&.strip
      return nil if url.blank? || title.blank?

      {
        title:       title[0, 200],
        company:     card.at_css(".base-search-card__subtitle a, .base-search-card__subtitle")&.text&.strip,
        location:    card.at_css(".job-search-card__location")&.text&.strip&.presence,
        url:         strip_tracking(url),
        posted_date: parse_date(card.at_css("time")&.[]("datetime"))
      }
    end

    # Apply URLs carry refId/trackingId/etc. that rotate per request —
    # strip the query string so by-URL dedup works across runs.
    def strip_tracking(url)
      url.split("?").first
    end

    def parse_date(s)
      Date.parse(s.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def infer_modality(raw)
      blob = "#{raw[:title]} #{raw[:location]}".downcase
      return "remoto"  if blob.include?("remote") || blob.include?("remoto")
      return "hibrido" if blob.include?("hybrid") || blob.include?("híbrido")
      "presencial"
    end

    def browser_ua
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
        "AppleWebKit/537.36 (KHTML, like Gecko) " \
        "Chrome/121.0.0.0 Safari/537.36"
    end
  end
end
