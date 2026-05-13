# Scrape a single source via the matching Scrapers client and record a
# ScraperRun row tracking the outcome. Enqueued manually via the API or
# automatically by sidekiq-cron (see config/schedule.yml).
class ScraperRunJob < ApplicationJob
  queue_as :scrapers

  # @param source_name [String] one of Scrapers::Registry::MAP keys ("adzuna", "itjobs")
  # @param params [Hash] forwarded to the client (e.g. keywords, where, role)
  def perform(source_name, params = {})
    run = ScraperRun.create!(source_name: source_name, params: params, status: "pending")
    run.mark_running!

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
      raise # let Sidekiq retry per its retry policy
    end
  end
end
