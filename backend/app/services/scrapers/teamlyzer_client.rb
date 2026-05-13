module Scrapers
  # Teamlyzer (`pt.teamlyzer.com/companies/jobs`) HTML listing scraper.
  # Each job is rendered as a `.row.jobboard-ad > .panel.jobcard` block
  # carrying:
  #   • data-company       on the row
  #   • .jobcard__title a  → job title + apply URL (UUID-based)
  #   • .jobcard__company  → company display name
  #   • .role-tag          → role classification (Backend, Frontend, ...)
  #
  # Apply URLs are stable (`/companies/get-job/{uuid}?v=jobboard`) so
  # they serve as the dedup key. The board paginates via `?page=N` —
  # we walk a few pages by default since one page only surfaces ~20
  # listings.
  class TeamlyzerClient < BaseClient
    SOURCE_NAME  = "teamlyzer"
    SOURCE_COLOR = "#e07a5f"
    BASE_URL     = "https://pt.teamlyzer.com"
    MAX_PAGES    = 5
    PAGE_DELAY   = 0.5

    def fetch_raw(params)
      pages = (params[:pages] || 3).to_i.clamp(1, MAX_PAGES)
      kw    = params[:keywords].to_s.downcase

      raws = []
      seen = Set.new
      (1..pages).each do |page_num|
        cards = fetch_page(page_num)
        break if cards.empty?

        new_in_page = 0
        cards.each do |card|
          attrs = extract_card(card)
          next unless attrs
          next if seen.include?(attrs[:url])
          next if kw.present? && !"#{attrs[:title]} #{attrs[:company]}".downcase.include?(kw)
          seen << attrs[:url]
          raws << attrs
          new_in_page += 1
        end
        break if new_in_page.zero?

        polite_sleep(PAGE_DELAY) if page_num < pages
      end
      raws
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

    def fetch_page(page_num)
      res = Faraday.get("#{BASE_URL}/companies/jobs") do |r|
        r.options.timeout = 25
        r.headers["User-Agent"] = "Mozilla/5.0 (+JobTracker/1.0)"
        r.params["page"] = page_num if page_num > 1
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?
      Nokogiri::HTML(res.body).css("div.row.jobboard-ad div.panel.jobcard")
    end

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
