# Scrape a single source via the matching Scrapers client and record a
# ScraperRun row tracking the outcome. Enqueued manually via the API,
# automatically by sidekiq-cron (see config/schedule.yml), or as a child
# of a SearchBatch (fan-out from POST /api/v1/search_batches).
class ScraperRunJob < ApplicationJob
  queue_as :scrapers

  # @param source_name [String] one of Scrapers::Registry.available
  # @param params [Hash] forwarded to the client (e.g. keywords, where, role)
  # @param search_batch_id [Integer, nil] when set, the run is linked to the
  #   batch and the batch's status is refreshed on every transition.
  def perform(source_name, params = {}, search_batch_id = nil)
    run = ScraperRun.create!(
      source_name:     source_name,
      params:          params,
      status:          "pending",
      search_batch_id: search_batch_id
    )
    run.mark_running!
    run.search_batch&.refresh_status!

    begin
      client = Scrapers::Registry.client_for(source_name)
      result = client.new.run(params.symbolize_keys)
      run.mark_succeeded!(
        found:   result[:found],
        created: result[:created],
        skipped: result[:skipped]
      )
    rescue => e
      Rails.logger.error("[ScraperRunJob/#{source_name}] #{e.class}: #{e.message}")
      run.mark_failed!("#{e.class}: #{e.message}")
      # Batched runs do NOT retry — Sidekiq retries would create extra
      # ScraperRun rows confusing the batch aggregate. Cron-triggered or
      # manual single-source runs keep the original retry semantics.
      raise if search_batch_id.nil?
    ensure
      run.search_batch&.refresh_status!
    end
  end
end
