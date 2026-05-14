module Api
  module V1
    # Lightweight source catalog for the OffersList filter UI. Returns every
    # Source row + how many non-archived Offers it currently owns, so the
    # frontend can render a chip list and dim/hide sources with zero offers.
    class SourcesController < ApplicationController
      # GET /api/v1/sources
      def index
        counts = Offer.active.group(:source_id).count
        rows = Source.order(:name).map do |s|
          {
            id:    s.id,
            name:  s.name,
            color: s.color,
            count: counts[s.id] || 0
          }
        end
        render json: rows
      end
    end
  end
end
