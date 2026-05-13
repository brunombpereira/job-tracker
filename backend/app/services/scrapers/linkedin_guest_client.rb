module Scrapers
  # LinkedIn jobs scraper using the unauthenticated SSR endpoint that
  # powers the public job-listings preview shown to logged-out visitors:
  #   /jobs-guest/jobs/api/seeMoreJobPostings/search
  #
  # The endpoint returns 40 job-card HTML fragments per page (paginated
  # via `start=0|40|80…`) without a login wall or Cloudflare challenge,
  # because LinkedIn explicitly exposes it for SEO and guest browsing.
  # We parse the fragments with Nokogiri and dedupe by the canonical
  # /jobs/view/{slug}-{id} URL each card carries.
  class LinkedinGuestClient < BaseClient
    SOURCE_NAME  = "linkedin"
    SOURCE_COLOR = "#0a66c2"

    ENDPOINT = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"

    # Time-posted filter codes that LinkedIn understands (`f_TPR`):
    #   r86400  → past 24 hours
    #   r604800 → past week
    #   r2592000 → past month
    TIME_FILTERS = {
      "day"   => "r86400",
      "week"  => "r604800",
      "month" => "r2592000",
    }.freeze

    def fetch_raw(params)
      keywords = params[:keywords].to_s.presence || "junior developer"
      location = params[:location].to_s.presence || "Portugal"
      time     = TIME_FILTERS[params[:time].to_s] # nil = any
      start_at = params[:start].to_i

      res = Faraday.get(ENDPOINT) do |r|
        r.options.timeout = 25
        r.headers["User-Agent"] = browser_ua
        r.headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        r.headers["Accept-Language"] = "en-US,en;q=0.9,pt;q=0.8"
        r.params["keywords"] = keywords
        r.params["location"] = location
        r.params["start"]    = start_at if start_at.positive?
        r.params["f_TPR"]    = time     if time
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      doc = Nokogiri::HTML(res.body)
      doc.css("li > div.base-search-card, div.base-card.base-search-card").map { |card| extract(card) }.compact
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

    def extract(card)
      url = card.at_css("a.base-card__full-link")&.[]("href")
      title = card.at_css(".base-search-card__title")&.text&.strip
      return nil if url.blank? || title.blank?

      {
        title:       title[0, 200],
        company:     card.at_css(".base-search-card__subtitle a, .base-search-card__subtitle")&.text&.strip,
        location:    card.at_css(".job-search-card__location")&.text&.strip&.presence,
        url:         strip_tracking(url),
        posted_date: parse_date(card.at_css("time")&.[]("datetime")),
      }
    end

    # The card's apply URL carries tracking params (refId, trackingId) that
    # change on every request and would break our by-URL dedup. Strip
    # everything after the query separator.
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

    # A current-ish Chrome UA — LinkedIn's guest endpoint serves the same
    # HTML for any browser-shaped client but rejects bare `curl` or
    # unrecognised UAs.
    def browser_ua
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
        "AppleWebKit/537.36 (KHTML, like Gecko) " \
        "Chrome/121.0.0.0 Safari/537.36"
    end
  end
end
