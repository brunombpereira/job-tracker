module Scrapers
  # Teamlyzer (`pt.teamlyzer.com/companies/jobs`) HTML listing scraper.
  # Each job is rendered as a `.row.jobboard-ad > .panel.jobcard` block
  # carrying:
  #   • data-company       on the row
  #   • .jobcard__title a  → job title + apply URL (UUID-based)
  #   • .jobcard__company  → company display name
  #   • .role-tag          → role classification (Backend, Frontend, ...)
  #
  # Apply URLs are stable (`/companies/get-job/{uuid}?v=jobboard`) so they
  # serve as the dedup key. A `keywords` param filters titles/companies
  # client-side.
  class TeamlyzerClient < BaseClient
    SOURCE_NAME  = "teamlyzer"
    SOURCE_COLOR = "#e07a5f"
    BASE_URL = "https://pt.teamlyzer.com"

    def fetch_raw(params)
      res = Faraday.get("#{BASE_URL}/companies/jobs") do |r|
        r.options.timeout = 25
        r.headers["User-Agent"] = "Mozilla/5.0 (+JobTracker/1.0)"
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      doc = Nokogiri::HTML(res.body)
      cards = doc.css("div.row.jobboard-ad div.panel.jobcard")

      kw = params[:keywords].to_s.downcase
      raws = cards.map { |card| extract_card(card) }.compact

      kw.present? ? raws.select { |r| "#{r[:title]} #{r[:company]}".downcase.include?(kw) } : raws
    rescue Faraday::Error => e
      raise FetchError, "Teamlyzer fetch failed: #{e.message}"
    end

    def normalize(raw)
      {
        title:       raw[:title],
        company:     raw[:company] || "Unknown",
        location:    nil, # Teamlyzer listing page doesn't expose city
        modality:    "presencial",
        url:         raw[:url],
        description: raw[:role_tag].present? ? "Categoria: #{raw[:role_tag]}" : nil,
        stack:       raw[:role_tag] ? [raw[:role_tag]] : [],
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    def extract_card(card)
      title_a = card.at_css(".jobcard__title a[href*='get-job']")
      return nil unless title_a

      href = title_a["href"]
      title = title_a.text.strip
      return nil if href.blank? || title.blank?

      {
        title:    title,
        company:  card.at_css(".jobcard__company")&.text&.strip,
        role_tag: card.at_css(".role-tag")&.text&.strip,
        url:      href.start_with?("http") ? href : "#{BASE_URL}#{href}"
      }
    end
  end
end
