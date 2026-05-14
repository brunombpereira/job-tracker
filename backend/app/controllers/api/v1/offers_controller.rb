module Api
  module V1
    class OffersController < ApplicationController
      before_action :set_offer, only: %i[show update destroy status]

      DEFAULT_PER_PAGE = 24
      # Upper bound on page size — the Kanban view legitimately asks for
      # 200 (see frontend KANBAN_LIMIT); anything above that is rejected
      # so a caller can't request the whole table in one page.
      MAX_PER_PAGE = 200

      # GET /api/v1/offers
      # Query params: include_archived=true to see archived offers in results.
      def index
        scope = Offer.includes(:source)
        scope = scope.active unless params[:include_archived] == "true"
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, offers = pagy(scope, items: per_page)

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
        offer = Offer.create!(offer_attrs)
        render json: offer, status: :created
      end

      # PATCH /api/v1/offers/:id
      def update
        @offer.update!(offer_attrs)
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

      # Attributes accepted from a bulk-import row.
      IMPORT_FIELDS = %i[
        title company location modality url status match_score
        salary_range company_size posted_date description source_id stack
      ].freeze

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
          attrs = row.with_indifferent_access.slice(*IMPORT_FIELDS)
          attrs[:stack] = Array(attrs[:stack]) if attrs.key?(:stack)

          result = Offers::Ingest.call(attrs)
          case result.outcome
          when :created
            created += 1
          when :invalid
            errors << { index: i, errors: result.errors }
          else
            skipped += 1
          end
        end

        render json: {
          created:     created,
          skipped:     skipped,
          error_count: errors.size,
          errors:      errors
        }
      end

      # DELETE /api/v1/offers/destroy_all
      # Soft-archives every active offer so the list reads as empty but
      # the URLs stay in the DB, preventing the next scrape from
      # re-importing offers the user discarded. Power users can pass
      # `?hard=true` to actually destroy the rows (URLs lost — the next
      # scrape will re-add anything still on the source).
      def destroy_all
        if params[:hard] == "true"
          scope = Offer.all
          scope = scope.active unless params[:include_archived] == "true"
          count = scope.count
          scope.destroy_all
          render json: { archived: 0, deleted: count }
        else
          archived = Offer.active.update_all(archived: true)
          render json: { archived: archived, deleted: 0 }
        end
      end

      # POST /api/v1/offers/import_url
      # Body: { url: "https://..." }
      # Fetches the URL server-side, extracts schema.org/JobPosting JSON-LD
      # (works for LinkedIn, Indeed, Glassdoor, and most ATSes), creates one
      # Offer. Returns the created Offer (201) or a friendly error (422).
      def import_url
        offer = Offers::UrlImporter.import(params.require(:url))
        render json: offer, status: :created
      rescue Offers::UrlImporter::ImportError => e
        render json: { error: e.message }, status: :unprocessable_entity
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

      def per_page
        requested = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        requested.clamp(1, MAX_PER_PAGE)
      end

      def offer_params
        params.require(:offer).permit(
          :title, :company, :location, :modality, :url, :status,
          :match_score, :salary_range, :company_size, :posted_date,
          :description, :source_id,
          stack: []
        )
      end

      def offer_attrs
        attrs = offer_params.to_h
        # A score typed into the form is the user's call — tag it so
        # `rake offers:rescore` leaves it alone.
        attrs[:score_source] = "manual" if attrs[:match_score].present?
        attrs
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
