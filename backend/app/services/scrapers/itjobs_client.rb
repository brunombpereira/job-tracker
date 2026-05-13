module Scrapers
  # ITJobs.pt RSS feed scraper.
  # No API key required. Public RSS at https://www.itjobs.pt/feed
  # Optional `role` param maps to one of their role slugs, e.g.
  #   "engenharia-informatica" / "programacao-web" / "back-end" / "front-end"
  class ItjobsClient < BaseClient
    SOURCE_NAME  = "itjobs"
    SOURCE_COLOR = "#ee6c4d"

    def fetch_raw(params)
      url = base_url(params)
      res = Faraday.get(url) { |r| r.options.timeout = 20 }
      raise FetchError, "HTTP #{res.status} from ITJobs.pt RSS" unless res.success?

      feed = Feedjira.parse(res.body)
      Array(feed&.entries)
    rescue Faraday::Error, Feedjira::NoParserAvailable => e
      raise FetchError, "ITJobs.pt fetch failed: #{e.message}"
    end

    def normalize(entry)
      title, company = split_title(entry.title)

      {
        title:       title,
        company:     company || "Unknown",
        location:    extract_location(entry.summary),
        modality:    infer_modality(entry.summary),
        url:         entry.url || entry.entry_id,
        description: ActionView::Base.full_sanitizer.sanitize(entry.summary.to_s)[0, 2000],
        posted_date: entry.published&.to_date,
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    def base_url(params)
      if params[:role].present?
        "https://www.itjobs.pt/api/feed/role/#{params[:role]}"
      else
        "https://www.itjobs.pt/feed"
      end
    end

    # ITJobs titles look like "Senior Ruby Developer (m/f) — Company Co"
    def split_title(raw)
      return [raw.to_s.strip, nil] if raw.blank?
      parts = raw.to_s.split(/\s+[—–-]\s+/, 2)
      parts.size == 2 ? [parts[0].strip, parts[1].strip] : [raw.to_s.strip, nil]
    end

    def extract_location(html)
      return nil if html.blank?
      text = ActionView::Base.full_sanitizer.sanitize(html.to_s)
      # ITJobs descriptions often have "Localização: Porto" or "Aveiro" mentioned
      match = text.match(/Localiza[çc][ãa]o:\s*([^\n,.]+)/i)
      match&.[](1)&.strip
    end

    def infer_modality(summary)
      blob = summary.to_s.downcase
      return "remoto"   if blob.include?("remoto") || blob.include?("remote")
      return "hibrido"  if blob.include?("h[íi]brido") || blob.include?("hybrid")
      "presencial"
    end
  end
end
