module Offers
  # Fills a missing offer description by fetching the offer's own listing
  # URL. The HTML-scraped sources (LinkedIn, Net-Empregos, Teamlyzer)
  # capture only the search-results card, not the detail page, so those
  # offers arrive with no description — this backfills it on demand, when
  # the user opens such an offer.
  class DescriptionFetcher
    def self.call(offer)
      new(offer).call
    end

    def initialize(offer)
      @offer = offer
    end

    # @return [Boolean] true when a description was fetched and saved
    def call
      return false if @offer.description.present?
      return false if @offer.url.blank?

      attrs = Offers::UrlImporter.extract(@offer.url)
      description = attrs[:description].presence
      return false unless description

      @offer.update!(description: description)
      true
    rescue Offers::UrlImporter::ImportError, ActiveRecord::RecordInvalid
      # On-demand enrichment — a failed fetch just means the offer keeps
      # no description, same as before. Don't surface it as an error.
      false
    end
  end
end
