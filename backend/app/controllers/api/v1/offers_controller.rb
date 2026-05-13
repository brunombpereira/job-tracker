module Api
  module V1
    class OffersController < ApplicationController
      before_action :set_offer, only: %i[show update destroy status]

      # GET /api/v1/offers
      # Query params: include_archived=true to see archived offers in results.
      def index
        scope = Offer.includes(:source)
        scope = scope.active unless params[:include_archived] == "true"
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, offers = pagy(scope, items: params.fetch(:per_page, 25))

        response.set_header("Total-Count",  pagy.count.to_s)
        response.set_header("Per-Page",     pagy.items.to_s)
        response.set_header("Current-Page", pagy.page.to_s)

        render json: offers.as_json(include: :source)
      end

      # GET /api/v1/offers/:id — includes source, notes (newest first),
      # status_changes (chronological)
      def show
        render json: @offer.as_json(
          include: {
            source:         {},
            notes:          { only: %i[id content created_at] },
            status_changes: { only: %i[id from_status to_status reason created_at] }
          }
        )
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

      # POST /api/v1/offers/import
      # Body: { offers: [ { title:, company:, ... }, ... ] }
      # Dedupes by url; skips duplicates silently. Returns counts.
      def import
        rows = Array(params[:offers]).map do |row|
          row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
        end
        created = 0
        skipped = 0
        errors  = []

        rows.each_with_index do |row, i|
          row = row.with_indifferent_access
          url = row[:url].to_s.strip

          if url.present? && Offer.exists?(url: url)
            skipped += 1
            next
          end

          attrs = row.slice(
            "title", "company", "location", "modality", "url", "status",
            "match_score", "salary_range", "company_size", "posted_date",
            "description", "source_id", "stack"
          )
          attrs["stack"] = Array(attrs["stack"]) if attrs.key?("stack")

          offer = Offer.new(attrs)
          if offer.save
            created += 1
          else
            errors << { index: i, errors: offer.errors.full_messages }
          end
        end

        render json: {
          created:     created,
          skipped:     skipped,
          error_count: errors.size,
          errors:      errors
        }
      end

      # GET /api/v1/offers/export.csv  or  .xlsx
      def export
        scope = apply_filters(apply_sort(Offer.includes(:source).active))

        respond_to do |format|
          format.csv  { send_data offers_csv(scope),  filename: "offers-#{Date.current}.csv",  type: "text/csv" }
          format.xlsx { render xlsx: "export", locals: { offers: scope }, filename: "offers-#{Date.current}.xlsx" }
        end
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

      CSV_HEADERS = %w[
        id title company location modality stack url status match_score
        salary_range company_size posted_date found_date applied_date source
      ].freeze

      def offers_csv(scope)
        require "csv"
        CSV.generate(headers: true) do |csv|
          csv << CSV_HEADERS
          scope.find_each do |o|
            csv << [
              o.id, o.title, o.company, o.location, o.modality,
              o.stack.join("|"), o.url, o.status, o.match_score,
              o.salary_range, o.company_size, o.posted_date, o.found_date,
              o.applied_date, o.source&.name
            ]
          end
        end
      end
    end
  end
end
