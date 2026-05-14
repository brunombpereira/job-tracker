module Offers
  # Single entry point for creating an Offer from data gathered elsewhere
  # — a bulk scraper run, a JSON import, or the single-URL importer.
  #
  # Before this existed, each of those three callers reimplemented the
  # same mechanics (dedup by URL, optional match scoring, rescue of
  # invalid rows) with subtle differences. Ingest centralises the
  # mechanics and reports an outcome; callers decide how to present it
  # (the URL importer raises, the bulk paths just count).
  class Ingest
    OUTCOMES = %i[created skipped_duplicate skipped_blank_url invalid].freeze

    Result = Struct.new(:offer, :outcome, :errors, keyword_init: true) do
      def created?
        outcome == :created
      end

      def skipped?
        %i[skipped_duplicate skipped_blank_url].include?(outcome)
      end
    end

    # @param attrs [Hash] Offer attributes (string or symbol keys)
    # @param source [Source, nil] source row to attribute the offer to
    # @param score [Boolean] assign match_score via ProfileMatcher when absent
    # @param skip_blank_url [Boolean] skip (vs. allow) offers without a URL —
    #   bulk scrapers skip them since they can't be deduped or clicked through
    def self.call(attrs, source: nil, score: true, skip_blank_url: false)
      new(attrs, source: source, score: score, skip_blank_url: skip_blank_url).call
    end

    def initialize(attrs, source:, score:, skip_blank_url:)
      @attrs          = attrs.to_h.symbolize_keys
      @source         = source
      @score          = score
      @skip_blank_url = skip_blank_url
    end

    def call
      url = @attrs[:url].to_s.strip.presence
      return result(:skipped_blank_url) if url.nil? && @skip_blank_url
      return result(:skipped_duplicate) if url && Offer.exists?(url: url)

      offer = build(url)
      if offer.save
        result(:created, offer: offer)
      else
        result(:invalid, errors: offer.errors.full_messages)
      end
    rescue ActiveRecord::RecordNotUnique
      # The URL unique index caught a row inserted between the exists?
      # check and the save — a concurrent ingest of the same listing.
      result(:skipped_duplicate)
    end

    private

    def build(url)
      attrs = @attrs.dup
      attrs[:url] = url
      attrs[:source_id] = @source.id if @source

      if @score && attrs[:match_score].blank?
        attrs[:match_score]  = Scorers::ProfileMatcher.score(attrs)
        attrs[:score_source] = "auto"
      end

      Offer.new(attrs)
    end

    def result(outcome, offer: nil, errors: [])
      Result.new(offer: offer, outcome: outcome, errors: errors)
    end
  end
end
