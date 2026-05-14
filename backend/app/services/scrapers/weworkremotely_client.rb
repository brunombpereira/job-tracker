module Scrapers
  # We Work Remotely RSS feed.
  # `https://weworkremotely.com/categories/<slug>.rss` — default category is
  # `remote-programming-jobs`. All listings are remote.
  class WeworkremotelyClient < BaseClient
    SOURCE_NAME  = "weworkremotely"
    SOURCE_COLOR = "#2d6a4f"

    def fetch_raw(params)
      category = params[:category].presence || "remote-programming-jobs"
      url = "https://weworkremotely.com/categories/#{category}.rss"
      res = Faraday.get(url) do |r|
        r.options.timeout = 20
        r.headers["User-Agent"] = "JobTracker/1.0"
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      feed = Feedjira.parse(res.body)
      Array(feed&.entries)
    rescue Faraday::Error, Feedjira::NoParserAvailable => e
      raise FetchError, "WeWorkRemotely fetch failed: #{e.message}"
    end

    def normalize(entry)
      title, company = split_title(entry.title)
      {
        title:       title,
        company:     company || "Unknown",
        location:    "Remote",
        modality:    "remoto",
        url:         entry.url || entry.entry_id,
        description: safe_html(entry.summary.to_s),
        posted_date: entry.published&.to_date,
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    # WWR titles look like "Company Name: Senior Backend Engineer"
    def split_title(raw)
      return [ raw.to_s.strip, nil ] if raw.blank?
      parts = raw.to_s.split(/:\s+/, 2)
      parts.size == 2 ? [ parts[1].strip, parts[0].strip ] : [ raw.to_s.strip, nil ]
    end
  end
end
