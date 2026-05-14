module Offers
  # Normalizes raw HTML — from a scraper feed or a fetched job page —
  # into the safe, lightly-formatted markup that the frontend's
  # DescriptionView renders. Keeps paragraphs, lists, emphasis, headings
  # and links; strips everything else.
  #
  # Some sources entity-encode their HTML (`&lt;strong&gt;` instead of
  # `<strong>`); that's decoded first, otherwise it renders as literal
  # tag text instead of formatting.
  module DescriptionSanitizer
    TAGS  = %w[p br ul ol li strong b em i h3 h4 h5 a code].freeze
    ATTRS = %w[href].freeze

    def self.call(html, max: 5000)
      return nil if html.blank?

      decoded = html.to_s
      if decoded.match?(/&lt;|&gt;|&amp;/)
        decoded = CGI.unescapeHTML(decoded).gsub(%r{<br\s*/?>}i, "<br>")
      end

      Rails::Html::SafeListSanitizer.new
        .sanitize(decoded, tags: TAGS, attributes: ATTRS)
        .strip[0, max]
    end
  end
end
