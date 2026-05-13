module Api
  module V1
    class OffersController < ApplicationController
      before_action :set_offer, only: %i[show update destroy status]

      # GET /api/v1/offers
      def index
        scope = Offer.includes(:source).active
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, offers = pagy(scope, items: params.fetch(:per_page, 25))

        response.set_header("Total-Count",  pagy.count.to_s)
        response.set_header("Per-Page",     pagy.items.to_s)
        response.set_header("Current-Page", pagy.page.to_s)

        render json: offers.as_json(include: :source)
      end

      # GET /api/v1/offers/:id
      def show
        render json: @offer.as_json(include: %i[source notes status_changes])
      end

      # POST /api/v1/offers
      def create
        offer = Offer.create!(offer_params)
        render json: offer, status: :created
      end

      # PATCH /api/v1/offers/:id
      def update
        @offer.update!(offer_params)
        render json: @offer
      end

      # DELETE /api/v1/offers/:id  (soft delete = archive)
      def destroy
        @offer.update!(archived: true)
        head :no_content
      end

      # PATCH /api/v1/offers/:id/status
      def status
        @offer.transition_to!(params.require(:status), reason: params[:reason])
        render json: @offer
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_offer
        @offer = Offer.find(params[:id])
      end

      def offer_params
        params.require(:offer).permit(
          :title, :company, :location, :modality, :url, :status,
          :match_score, :salary_range, :company_size, :posted_date,
          :description, :source_id,
          stack: []
        )
      end

      def apply_filters(scope)
        scope = scope.where(status: params[:status].to_s.split(",")) if params[:status].present?
        scope = scope.where(modality: params[:modality]) if params[:modality].present?
        scope = scope.where("match_score >= ?", params[:match_score_gte]) if params[:match_score_gte].present?
        scope = scope.where("match_score <= ?", params[:match_score_lte]) if params[:match_score_lte].present?
        scope = scope.where("location ILIKE ?", "%#{params[:location]}%") if params[:location].present?
        scope = scope.where(source_id: params[:source_id]) if params[:source_id].present?
        if params[:search].present?
          q = "%#{params[:search]}%"
          scope = scope.where("title ILIKE :q OR company ILIKE :q OR description ILIKE :q", q: q)
        end
        scope
      end

      def apply_sort(scope)
        sort = params.fetch(:sort, "match_score:desc")
        field, dir = sort.split(":")
        return scope unless Offer::SORTABLE.include?(field) && %w[asc desc].include?(dir)

        scope.order(field => dir)
      end
    end
  end
end
