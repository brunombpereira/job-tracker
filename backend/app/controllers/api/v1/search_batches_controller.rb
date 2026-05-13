module Api
  module V1
    # Batched multi-source search. The frontend hits POST once with no body
    # (or an optional `sources` array) to fire every ready scraper in
    # parallel, then polls GET /:id until the batch is terminal.
    class SearchBatchesController < ApplicationController
      # POST /api/v1/search_batches
      # Body (optional):
      #   { sources: ["adzuna", "itjobs"], params_by_source: { "adzuna": {...} } }
      # When `sources` is omitted, every ready (credential-present) source
      # in Scrapers::Registry is dispatched.
      def create
        requested = Array(params[:sources]).map(&:to_s)
        requested = Scrapers::Registry.ready if requested.empty?

        invalid = requested - Scrapers::Registry.available
        return render(json: { error: "Unknown sources: #{invalid.join(', ')}" },
                      status: :unprocessable_entity) if invalid.any?

        return render(json: { error: "No ready sources to dispatch" },
                      status: :unprocessable_entity) if requested.empty?

        params_by_source = params[:params_by_source]&.to_unsafe_h || {}

        batch = SearchBatch.create!(
          status:            "pending",
          sources_requested: requested,
          started_at:        Time.current
        )

        requested.each do |source_key|
          source = Scrapers::Registry.find(source_key)
          job_params = params_by_source[source_key] || source.default_params
          ScraperRunJob.perform_later(source_key, job_params, batch.id)
        end

        render json: serialize(batch.reload), status: :accepted
      end

      # GET /api/v1/search_batches/:id
      # Returns the batch + each child ScraperRun for the frontend to
      # render per-source progress.
      def show
        batch = SearchBatch.find(params[:id])
        render json: serialize(batch)
      end

      private

      def serialize(batch)
        {
          id:                batch.id,
          status:            batch.status,
          sources_requested: batch.sources_requested,
          offers_found:      batch.offers_found,
          offers_created:    batch.offers_created,
          offers_skipped:    batch.offers_skipped,
          started_at:        batch.started_at,
          finished_at:       batch.finished_at,
          created_at:        batch.created_at,
          runs:              batch.scraper_runs.order(:created_at).as_json(only: %i[
            id source_name status offers_found offers_created offers_skipped
            error_message started_at finished_at
          ])
        }
      end
    end
  end
end
