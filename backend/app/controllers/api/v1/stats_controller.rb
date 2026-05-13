module Api
  module V1
    class StatsController < ApplicationController
      # GET /api/v1/stats
      # Returns funnel counts + conversion rates per source.
      def index
        scope = Offer.active

        funnel = Offer::STATUSES.index_with do |status|
          scope.where(status: status).count
        end

        by_source = Source.left_outer_joins(:offers)
                          .where(offers: { archived: [false, nil] })
                          .group("sources.id", "sources.name")
                          .order("sources.name")
                          .count("offers.id")
                          .map { |(_id, name), count| { name: name, count: count } }

        recent = scope.recent(7).count

        render json: {
          total:      scope.count,
          recent_7d:  recent,
          funnel:     funnel,
          by_source:  by_source,
          updated_at: Time.current.iso8601
        }
      end
    end
  end
end
