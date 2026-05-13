module Scrapers
  # Shared interface for all scraper clients. Subclasses override SOURCE_NAME,
  # implement #fetch_raw(params) → [Hash, ...], and #normalize(raw) → attrs.
  #
  # The orchestrator calls #run(params) which:
  #   1. ensures a Source row for this scraper exists
  #   2. fetches raw offers (per source-specific shape)
  #   3. normalizes each to an Offer-compatible Hash
  #   4. assigns a match_score via Scorers::ProfileMatcher
  #   5. dedupes by URL and bulk-creates new Offers
  #   6. returns counts: { found:, created:, skipped: }
  class BaseClient
    SOURCE_NAME = nil # subclasses override

    class FetchError < StandardError; end

    def self.run(params = {})
      new.run(params)
    end

    def initialize
      raise NotImplementedError, "subclass must set SOURCE_NAME" if source_name.nil?
    end

    def source_name
      self.class::SOURCE_NAME
    end

    def run(params = {})
      source = ensure_source!
      raws   = fetch_raw(params)
      attrs  = raws.map { |r| normalize(r) }.compact

      created = 0
      skipped = 0
      attrs.each do |a|
        next skipped += 1 if a[:url].blank?
        next skipped += 1 if Offer.exists?(url: a[:url])

        a[:match_score] ||= Scorers::ProfileMatcher.score(a)
        Offer.create!(a.merge(source_id: source.id))
        created += 1
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        skipped += 1
      end

      { found: attrs.size, created: created, skipped: skipped }
    end

    # Hooks for subclasses
    def fetch_raw(_params)
      raise NotImplementedError
    end

    def normalize(_raw)
      raise NotImplementedError
    end

    # Shared description sanitizer. Allows the lightweight markup that
    # makes descriptions readable (paragraphs, lists, emphasis, headings,
    # links) and strips everything else. Subclasses call this in their
    # normalize() instead of writing their own truncate_html helpers.
    DESCRIPTION_TAGS = %w[p br ul ol li strong b em i h3 h4 h5 a code].freeze
    DESCRIPTION_ATTRS = %w[href].freeze

    def safe_html(html, max: 5000)
      return nil if html.blank?
      decoded = html.to_s
      decoded = CGI.unescapeHTML(decoded).gsub(/<br\s*\/?>/i, "<br>") if decoded.match?(/&lt;|&gt;|&amp;/)
      sanitized = Rails::Html::SafeListSanitizer.new.sanitize(
        decoded,
        tags: DESCRIPTION_TAGS,
        attributes: DESCRIPTION_ATTRS,
      )
      sanitized.strip[0, max]
    end

    private

    def ensure_source!
      Source.find_or_create_by!(name: source_name.to_s.titleize) do |s|
        s.color = self.class::SOURCE_COLOR if self.class.const_defined?(:SOURCE_COLOR)
      end
    end

    def http
      @http ||= Faraday.new do |f|
        f.request  :json
        f.response :json, content_type: /\bjson$/
        f.options.timeout      = 20
        f.options.open_timeout = 5
      end
    end
  end
end
