module Scrapers
  # Landing.jobs public REST API — `https://landing.jobs/api/v1/jobs`.
  # Returns an array of job hashes (not wrapped). Company name is not in the
  # response shape; we derive it from the `/at/{slug}/...` segment of the
  # job URL.
  class LandingJobsClient < BaseClient
    SOURCE_NAME  = "landing_jobs"
    SOURCE_COLOR = "#7b2cbf"

    def fetch_raw(params)
      url = "https://landing.jobs/api/v1/jobs"
      res = http.get(url) do |req|
        req.params["limit"]  = params[:limit] || 50
        req.params["offset"] = params[:offset] if params[:offset]
        req.headers["User-Agent"] = "JobTracker/1.0"
        if (token = ENV["LANDING_JOBS_TOKEN"]).present?
          req.headers["Authorization"] = "Token token=\"#{token}\""
        end
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      Array(res.body.is_a?(Array) ? res.body : res.body["jobs"])
    rescue Faraday::Error => e
      raise FetchError, "Landing.jobs fetch failed: #{e.message}"
    end

    def normalize(raw)
      {
        title:        raw["title"].to_s.strip,
        company:      company_from_url(raw["url"]) || "Landing.jobs",
        location:     format_location(raw["locations"]),
        modality:     raw["remote"] ? "remoto" : "presencial",
        url:          raw["url"],
        description:  safe_html(raw["role_description"]),
        posted_date:  raw["published_at"]&.then { |d| Date.parse(d) rescue nil },
        salary_range: format_salary(raw),
        stack:        Array(raw["tags"]),
        status:       "new"
      }
    rescue StandardError
      nil
    end

    private

    # URL shape: https://landing.jobs/at/{company-slug}/{job-slug}
    def company_from_url(url)
      return nil if url.blank?
      match = url.match(%r{landing\.jobs/at/([^/]+)/})
      match && match[1].tr("-", " ").split.map(&:capitalize).join(" ")
    end

    def format_location(locations)
      Array(locations)
        .map { |l| [ l["city"], l["country_code"] ].compact.join(", ") }
        .reject(&:empty?)
        .join(" / ")
        .presence
    end

    def format_salary(raw)
      lo, hi = raw["gross_salary_low"], raw["gross_salary_high"]
      return nil unless lo || hi
      cur = raw["currency_code"].to_s.presence || "EUR"
      sym = cur == "EUR" ? "€" : "#{cur} "
      [ lo, hi ].compact.map { |n| "#{sym}#{Integer(n) / 1000}k" }.join("–")
    rescue StandardError
      nil
    end
  end
end
