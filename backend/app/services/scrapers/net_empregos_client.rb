module Scrapers
  # Net-Empregos category-listing scraper (HTML, paginated).
  #
  # The public RSS at /rssfeed.asp is a 250-item rolling feed across
  # every job category — only ~4 Programação listings tend to be in
  # there at any time even though the site itself has 1.5k+ active
  # Programação offers. So we scrape the actual category page:
  #
  #   /empregos-portugal-informatica-programacao.asp?categoria=5&zona=0&page=N
  #
  # which serves 18 listings per page in static HTML (no JS hydration
  # needed). We loop through `pages` pages, dedup by URL, and stop
  # early if a page returns 0 new items.
  class NetEmpregosClient < BaseClient
    SOURCE_NAME  = "net_empregos"
    SOURCE_COLOR = "#1d3557"

    BASE_URL              = "https://www.net-empregos.com"
    # Category 5 = "Informática ( Programação )"; its canonical listing
    # path bakes the slug + category id together. Other categories use
    # different slugs, so swap both via params if/when needed.
    DEFAULT_CATEGORY_PATH = "empregos-portugal-informatica-programacao.asp"
    DEFAULT_CATEGORIA     = 5
    MAX_PAGES             = 8
    PAGE_DELAY            = 0.5  # seconds, between paginated requests

    def fetch_raw(params)
      pages     = (params[:pages] || 3).to_i.clamp(1, MAX_PAGES)
      categoria = (params[:categoria] || DEFAULT_CATEGORIA).to_i
      path      = params[:category_path].to_s.strip.presence || DEFAULT_CATEGORY_PATH

      raws = []
      seen = Set.new
      (1..pages).each do |page_num|
        items = fetch_page(path, categoria, page_num)
        break if items.empty?

        new_in_page = 0
        items.each do |item|
          attrs = extract(item)
          next unless attrs
          next if seen.include?(attrs[:url])
          seen << attrs[:url]
          raws << attrs
          new_in_page += 1
        end
        break if new_in_page.zero?

        polite_sleep(PAGE_DELAY) if page_num < pages
      end
      raws
    rescue Faraday::Error => e
      raise FetchError, "Net-Empregos fetch failed: #{e.message}"
    end

    def normalize(raw)
      {
        title:       raw[:title],
        company:     raw[:company].presence || "Unknown",
        location:    raw[:location],
        modality:    infer_modality("#{raw[:title]} #{raw[:category]}"),
        url:         raw[:url],
        # The listing page intentionally omits the description blurb;
        # offers point to the canonical /:id/:slug/ detail page.
        description: nil,
        posted_date: parse_pt_date(raw[:date]),
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    def fetch_page(path, categoria, page_num)
      res = Faraday.get("#{BASE_URL}/#{path}") do |r|
        r.options.timeout = 20
        r.headers["User-Agent"] = "JobTracker/1.0"
        r.params["categoria"] = categoria
        r.params["zona"]      = 0
        r.params["page"]      = page_num if page_num > 1
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      # Site declares iso-8859-1 in the prolog but Faraday hands us raw
      # bytes; force the encoding then transcode to UTF-8.
      body_utf8 = res.body.dup.force_encoding("ISO-8859-1").encode(
        "UTF-8", invalid: :replace, undef: :replace
      )
      Nokogiri::HTML(body_utf8).css("div.job-item")
    end

    def extract(item)
      anchor = item.at_css("h2 a.oferta-link")
      return nil unless anchor

      href = anchor["href"].to_s
      return nil if href.blank?

      lis = item.css(".job-ad-item ul li").map { |li| li.text.gsub(/\s+/, " ").strip }
      # Order baked into the template: [date, location, category, company]
      {
        title:    anchor.text.strip,
        url:      href.start_with?("http") ? href : "#{BASE_URL}#{href}",
        date:     lis[0],
        location: lis[1],
        category: lis[2],
        company:  lis[3]
      }
    end

    def parse_pt_date(s)
      return nil if s.blank?
      Date.strptime(s.to_s, "%d-%m-%Y")
    rescue ArgumentError
      nil
    end

    def infer_modality(blob)
      lower = blob.to_s.downcase
      return "remoto"  if lower.match?(/remoto|teletrabalho|remote/)
      return "hibrido" if lower.match?(/h[íi]brido|hybrid/)
      "presencial"
    end
  end
end
