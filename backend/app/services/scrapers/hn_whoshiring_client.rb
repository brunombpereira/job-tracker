module Scrapers
  # Hacker News "Ask HN: Who is hiring?" monthly thread.
  # Uses the official Firebase API. Steps:
  #   1. fetch the `whoishiring` user → their `submitted` list
  #   2. walk submissions, find the most recent "Who is hiring?" thread
  #   3. fetch the thread item → its `kids` are top-level comment ids
  #   4. fetch each kid; parse the first line for company | title | location
  #
  # The first comment-line convention is "Company | Role | Location | REMOTE
  # / ONSITE | tags". We extract the first two pipes; everything else lands
  # in description and location is inferred from "REMOTE"/"ONSITE" keywords.
  class HnWhoshiringClient < BaseClient
    SOURCE_NAME  = "hn_whoshiring"
    SOURCE_COLOR = "#ff6600"
    MAX_COMMENTS = 60

    def fetch_raw(params)
      keywords = params[:keywords].to_s.downcase
      thread_id = locate_thread_id
      raise FetchError, "No 'Who is hiring' thread found" unless thread_id

      thread = fetch_item(thread_id)
      kid_ids = Array(thread["kids"]).first(MAX_COMMENTS)

      comments = kid_ids.map { |id| fetch_item(id) }.compact
      comments = comments.reject { |c| c["deleted"] || c["dead"] || c["text"].blank? }

      if keywords.present?
        comments = comments.select { |c| c["text"].to_s.downcase.include?(keywords) }
      end

      comments.map { |c| c.merge("_thread_url" => "https://news.ycombinator.com/item?id=#{thread_id}") }
    rescue Faraday::Error => e
      raise FetchError, "HN fetch failed: #{e.message}"
    end

    def normalize(raw)
      text = decode_text(raw["text"])
      first_line, rest = text.split(/\n|<p>/, 2)
      parts = first_line.to_s.split(/\s*[|·]\s*/).map(&:strip)

      company = parts[0].presence || "Unknown"
      title   = parts[1].presence || "(see comment)"
      location_blob = parts[2..]&.join(" | ").to_s
      remote = first_line.to_s.match?(/remote/i)

      {
        title:       title[0, 200],
        company:     company[0, 200],
        location:    location_blob.presence,
        modality:    remote ? "remoto" : "presencial",
        url:         "https://news.ycombinator.com/item?id=#{raw['id']}",
        description: [first_line, rest].compact.join("\n").to_s[0, 2000],
        posted_date: raw["time"] ? Time.at(raw["time"]).to_date : nil,
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    def locate_thread_id
      user = fetch_json("https://hacker-news.firebaseio.com/v0/user/whoishiring.json")
      submitted = Array(user["submitted"])
      # Walk newest-first; first one whose title starts with "Ask HN: Who is hiring?" wins.
      submitted.each do |id|
        item = fetch_item(id)
        return id if item["title"].to_s.match?(/Who is hiring\?/i)
      end
      nil
    end

    def fetch_item(id)
      fetch_json("https://hacker-news.firebaseio.com/v0/item/#{id}.json") || {}
    end

    def fetch_json(url)
      res = http.get(url) { |r| r.headers["User-Agent"] = "JobTracker/1.0" }
      raise FetchError, "HTTP #{res.status} from HN" unless res.success?
      res.body
    end

    def decode_text(html)
      return "" if html.blank?
      txt = html.to_s.gsub(/<p>/, "\n").gsub(/<\/?[^>]+>/, "")
      CGI.unescapeHTML(txt).strip
    end
  end
end
