module Api
  module V1
    class ScraperRunsController < ApplicationController
      # GET /api/v1/scraper_runs
      # Returns the latest 50 runs across all sources, plus the registered
      # source list (so the UI can render an enqueue button per source).
      def index
        runs = ScraperRun.recent.limit(50)
        render json: {
          sources: Scrapers::Registry.available,
          runs:    runs.as_json(only: %i[
            id source_name status offers_found offers_created offers_skipped
            params error_message started_at finished_at created_at
          ])
        }
      end

      # POST /api/v1/scraper_runs
      # Body: { source: "adzuna", params: { keywords: "...", where: "..." } }
      # Enqueues a one-off ScraperRunJob immediately.
      def create
        source = params.require(:source)
        job_params = params[:params].respond_to?(:to_unsafe_h) ? params[:params].to_unsafe_h : (params[:params] || {})
        raise ArgumentError, "unknown source" unless Scrapers::Registry.available.include?(source)

        ScraperRunJob.perform_later(source, job_params)
        render json: { enqueued: true, source: source, params: job_params }, status: :accepted
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
