module Scrapers
  # Remotive open JSON API — `https://remotive.com/api/remote-jobs`.
  # No auth required, but Remotive request attribution; we set `source_id` on
  # Offers and link back via `url`. Per their ToS, do not republish elsewhere.
  class RemotiveClient < BaseClient
    SOURCE_NAME  = "remotive"
    SOURCE_COLOR = "#3da5d9"

    def fetch_raw(params)
      url = "https://remotive.com/api/remote-jobs"
      res = http.get(url) do |req|
        req.params["category"] = params[:category] if params[:category].to_s.strip != ""
        req.params["search"]   = params[:search]   if params[:search].to_s.strip != ""
        req.params["limit"]    = params[:limit] || 50
        req.headers["User-Agent"] = "JobTracker/1.0 (+personal use)"
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      Array(res.body["jobs"])
    rescue Faraday::Error => e
      raise FetchError, "Remotive fetch failed: #{e.message}"
    end

    def normalize(raw)
      {
        title:        raw["title"].to_s.strip,
        company:      raw["company_name"].to_s.strip.presence || "Unknown",
        location:     raw["candidate_required_location"].presence,
        modality:     "remoto",
        url:          raw["url"],
        description:  sanitize(raw["description"]),
        posted_date:  raw["publication_date"]&.then { |d| Date.parse(d) rescue nil },
        salary_range: raw["salary"].to_s.strip.presence,
        status:       "new"
      }
    rescue StandardError
      nil
    end

    private

    def sanitize(html, max: 2000)
      return nil if html.blank?
      ActionView::Base.full_sanitizer.sanitize(html).to_s.strip[0, max]
    end
  end
end
