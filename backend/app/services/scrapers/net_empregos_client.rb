module Scrapers
  # Net-Empregos public RSS feed at `/rssfeed.asp`. Encoding is iso-8859-1
  # and the description carries structured "Empresa:/Categoria:/Zona:/Descrição:"
  # fields rendered as HTML.
  #
  # The feed itself ignores any `categoria=` query parameter and returns
  # all 250 most-recent listings (mixed categories), so we filter
  # client-side on the parsed Categoria field — `category: "Programação"`
  # by default. A `keywords` param does an additional title/description
  # substring match on top.
  class NetEmpregosClient < BaseClient
    SOURCE_NAME  = "net_empregos"
    SOURCE_COLOR = "#1d3557"

    def fetch_raw(params)
      url = "https://www.net-empregos.com/rssfeed.asp"
      res = Faraday.get(url) do |r|
        r.options.timeout = 20
        r.headers["User-Agent"] = "JobTracker/1.0"
      end
      raise FetchError, "HTTP #{res.status}" unless res.success?

      body = transcode_to_utf8(res.body)
      feed = Feedjira.parse(body)
      entries = Array(feed&.entries)

      category = params[:category].to_s.strip.downcase
      keywords = params[:keywords].to_s.strip.downcase

      entries = entries.select { |e| parsed_category(e).include?(category) } if category.present?
      entries = entries.select { |e| "#{e.title} #{e.summary}".downcase.include?(keywords) } if keywords.present?

      entries
    rescue Faraday::Error, Feedjira::NoParserAvailable => e
      raise FetchError, "Net-Empregos fetch failed: #{e.message}"
    end

    def normalize(entry)
      # Source wraps already-encoded HTML inside CDATA — unescape entities
      # first, then convert <br> to newlines so the sanitizer-stripped
      # text retains the per-field boundary the regex parser needs.
      decoded = CGI.unescapeHTML(entry.summary.to_s).gsub(/<br\s*\/?>/i, "\n")
      text = ActionView::Base.full_sanitizer.sanitize(decoded)
      fields = parse_fields(text)

      {
        title:       entry.title.to_s.strip,
        company:     entry.author.to_s.strip.presence || fields["Empresa"] || "Unknown",
        location:    fields["Zona"],
        modality:    infer_modality("#{entry.title} #{text}"),
        url:         entry.url || entry.entry_id,
        description: clean_description(text),
        posted_date: entry.published&.to_date,
        status:      "new"
      }
    rescue StandardError
      nil
    end

    private

    LABELS = %w[Empresa Categoria Zona Data Descrição].freeze

    # Net-Empregos serves the feed as iso-8859-1, but unit tests inline
    # UTF-8 XML — read the declared encoding from the prolog and only
    # transcode when it isn't already UTF-8.
    def transcode_to_utf8(body)
      declared = body.byteslice(0, 200).to_s.match(/encoding=["']([^"']+)["']/i)&.[](1)
      return body if declared.nil? || declared.upcase == "UTF-8"

      body.dup.force_encoding(declared).encode("UTF-8", invalid: :replace, undef: :replace)
    end

    def parsed_category(entry)
      decoded = CGI.unescapeHTML(entry.summary.to_s).gsub(/<br\s*\/?>/i, "\n")
      text = ActionView::Base.full_sanitizer.sanitize(decoded)
      parse_fields(text)["Categoria"].to_s.downcase
    end

    def parse_fields(text)
      LABELS.each_with_object({}) do |label, out|
        match = text.match(/#{label}:\s*([^\n]+)/)
        out[label] = match&.[](1)&.strip.presence
      end
    end

    def clean_description(text)
      stripped = text.sub(/Ver Oferta de Emprego.*\z/m, "")
                     .sub(/.*?Descrição:\s*/m, "")
                     .strip
      stripped[0, 2000]
    end

    def infer_modality(blob)
      lower = blob.to_s.downcase
      return "remoto"  if lower.include?("remoto") || lower.include?("teletrabalho")
      return "hibrido" if lower.include?("híbrido") || lower.include?("hibrido")
      "presencial"
    end
  end
end
