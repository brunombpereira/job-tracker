module Scrapers
  # Adzuna REST API client.
  # Requires ADZUNA_APP_ID and ADZUNA_APP_KEY env vars (free registration at
  # https://developer.adzuna.com).
  #
  # Country code defaults to "pt"; pass `country: "gb"` etc. via params.
  class AdzunaClient < BaseClient
    SOURCE_NAME  = "adzuna"
    SOURCE_COLOR = "#0a9396"
    DEFAULT_COUNTRY = "pt"
    DEFAULT_PER_PAGE = 50

    def fetch_raw(params)
      app_id  = ENV.fetch("ADZUNA_APP_ID")  { raise FetchError, "ADZUNA_APP_ID not set" }
      app_key = ENV.fetch("ADZUNA_APP_KEY") { raise FetchError, "ADZUNA_APP_KEY not set" }

      country  = params[:country]  || DEFAULT_COUNTRY
      keywords = params[:keywords] || "developer"
      where    = params[:where]    || "Portugal"
      per_page = params[:per_page] || DEFAULT_PER_PAGE

      url = "https://api.adzuna.com/v1/api/jobs/#{country}/search/1"
      res = http.get(url) do |req|
        req.params["app_id"]          = app_id
        req.params["app_key"]         = app_key
        req.params["what"]            = keywords
        req.params["where"]           = where
        req.params["results_per_page"] = per_page
        req.params["sort_by"]          = "date"
        req.params["content-type"]     = "application/json"
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      Array(res.body["results"])
    rescue Faraday::Error => e
      raise FetchError, "Adzuna fetch failed: #{e.message}"
    end

    def normalize(raw)
      {
        title:        raw["title"].to_s.strip,
        company:      raw.dig("company", "display_name").to_s.strip,
        location:     raw.dig("location", "display_name"),
        modality:     infer_modality(raw),
        url:          raw["redirect_url"],
        description:  truncate_html(raw["description"]),
        posted_date:  raw["created"]&.then { |d| Date.parse(d) rescue nil },
        salary_range: salary_string(raw),
        status:       "new"
      }
    rescue StandardError
      nil
    end

    private

    def infer_modality(raw)
      blob = "#{raw["title"]} #{raw["description"]}".downcase
      return "remoto"    if blob.include?("remote") || blob.include?("remoto")
      return "hibrido"   if blob.include?("hybrid") || blob.include?("híbrido")
      "presencial"
    end

    def truncate_html(s, max: 2000)
      return nil if s.blank?
      ActionView::Base.full_sanitizer.sanitize(s).to_s.strip[0, max]
    end

    def salary_string(raw)
      lo = raw["salary_min"]
      hi = raw["salary_max"]
      return nil unless lo || hi
      [lo && Integer(lo), hi && Integer(hi)].compact.map { |n| "€#{n / 1000}k" }.join("–")
    rescue StandardError
      nil
    end
  end
end
