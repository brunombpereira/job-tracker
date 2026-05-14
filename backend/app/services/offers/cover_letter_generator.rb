module Offers
  # Fills the mustache-style `{{token}}` placeholders in the PT/EN
  # cover-letter templates with data drawn from one Offer + the user's
  # Profile.
  #
  # Returns plain markdown text. Anything still wrapped in `[…]` is a
  # human placeholder (the "specific company hook" paragraph) — the
  # generator deliberately doesn't try to write the heartfelt bit for
  # the user.
  class CoverLetterGenerator
    SUPPORTED_LANGS = %w[pt en].freeze

    class MissingTemplate < StandardError; end

    def self.generate(offer:, lang: "pt")
      new(offer: offer, lang: lang).generate
    end

    def initialize(offer:, lang:)
      @offer = offer
      @lang  = SUPPORTED_LANGS.include?(lang.to_s) ? lang.to_s : "pt"
    end

    def generate
      template = read_template
      tokens.reduce(template) do |text, (key, value)|
        text.gsub("{{#{key}}}", value.to_s)
      end
    end

    def filename
      base = @offer.company.to_s.parameterize.presence || "company"
      "Cover_Letter_#{base}_#{@lang.upcase}.md"
    end

    private

    def read_template
      doc = ProfileDocument.for_kind("template_#{@lang}")
      raise MissingTemplate, "no cover-letter template uploaded for '#{@lang}'" unless doc

      # Stored as bytes (bytea); the template is UTF-8 markdown.
      doc.data.dup.force_encoding(Encoding::UTF_8)
    end

    def tokens
      {
        "city"           => profile_city,
        "date"           => today,
        "company"        => @offer.company.to_s.presence || "[Nome da Empresa]",
        "position_title" => @offer.title.to_s.presence  || "[Título da posição]",
        "platform"       => platform_label,
        "recipient_name" => recipient_placeholder,
        "start_date"     => profile_start_date
      }
    end

    def profile
      @profile ||= Profile.current
    end

    def profile_city
      profile.city.to_s.presence || (@lang == "en" ? "[Your city]" : "[A tua cidade]")
    end

    def profile_start_date
      profile.start_date.to_s.presence ||
        (@lang == "en" ? "immediately" : "imediato")
    end

    def platform_label
      name = @offer.source&.name.to_s.presence
      return name if name

      @lang == "en" ? "your careers page" : "a vossa página de carreiras"
    end

    def recipient_placeholder
      @lang == "en" ? "[Hiring Manager Name]" : "[Nome do Recrutador]"
    end

    def today
      locale = (@lang == "en" ? "%B %-d, %Y" : "%-d de %B de %Y")
      I18n.with_locale(@lang == "en" ? :en : :"pt-PT") { Time.current.strftime(locale) }
    rescue I18n::InvalidLocale
      Time.current.strftime("%Y-%m-%d")
    end
  end
end
