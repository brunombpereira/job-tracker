module Offers
  # Fills the mustache-style `{{token}}` placeholders in the PT/EN
  # cover-letter templates from `storage/profile/cover_letters/` with
  # data drawn from one Offer + the global profile config.
  #
  # Returns plain markdown text. Anything still wrapped in `[…]` is a
  # human placeholder (the "specific company hook" paragraph) — the
  # generator deliberately doesn't try to write the heartfelt bit for
  # the user.
  class CoverLetterGenerator
    SUPPORTED_LANGS = %w[pt en].freeze
    TEMPLATE_DIR    = Rails.root.join("storage", "profile", "cover_letters")

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
      path = TEMPLATE_DIR.join("template_#{@lang}.md")
      raise MissingTemplate, "no template at #{path}" unless path.exist?
      path.read
    end

    def tokens
      {
        "city"           => profile_city,
        "date"           => today,
        "company"        => @offer.company.to_s.presence || "[Nome da Empresa]",
        "position_title" => @offer.title.to_s.presence  || "[Título da posição]",
        "platform"       => platform_label,
        "recipient_name" => recipient_placeholder,
        "start_date"     => profile_start_date,
      }
    end

    def profile_config
      Scorers::ProfileMatcher.config
    end

    def profile_city
      profile_config["city"].to_s.presence || "Aveiro"
    end

    def profile_start_date
      profile_config["start_date"].to_s.presence ||
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
