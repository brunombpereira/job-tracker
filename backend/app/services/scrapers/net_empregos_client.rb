module Scrapers
  # Net-Empregos public RSS feed at `/rssfeed.asp`. Encoding is iso-8859-1
  # and the description carries structured "Empresa:/Categoria:/Zona:/Descrição:"
  # fields rendered as HTML, which we parse out for clean Offer attrs.
  #
  # A `keywords` param filters entries client-side by title/description
  # (the feed itself is unfiltered).
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

      body = res.body.dup.force_encoding("ISO-8859-1").encode("UTF-8", invalid: :replace, undef: :replace)
      feed = Feedjira.parse(body)
      entries = Array(feed&.entries)

      kw = params[:keywords].to_s.downcase
      if kw.present?
        entries = entries.select do |e|
          "#{e.title} #{e.summary}".to_s.downcase.include?(kw)
        end
      end
      entries
    rescue Faraday::Error, Feedjira::NoParserAvailable => e
      raise FetchError, "Net-Empregos fetch failed: #{e.message}"
    end

    def normalize(entry)
      # Source wraps already-encoded HTML inside CDATA — unescape entities
      # first, then convert <br> to newlines so the sanitizer-stripped text
      # retains the per-field boundary the regex parser needs.
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

    # Strip the trailing "Ver Oferta de Emprego" / "Emprego" link boilerplate
    # and parse the labelled prefix into a Hash.
    LABELS = %w[Empresa Categoria Zona Data Descrição].freeze

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
