module Scrapers
  # Maps source slug → client class. Single source of truth for what's
  # available to the scheduler and the manual-trigger UI.
  #
  # Class names stored as strings + .constantize at call time so Zeitwerk
  # doesn't load every client when this file is autoloaded.
  module Registry
    MAP = {
      "adzuna" => "Scrapers::AdzunaClient",
      "itjobs" => "Scrapers::ItjobsClient"
    }.freeze

    def self.client_for(slug)
      klass_name = MAP[slug.to_s] or
        raise ArgumentError, "Unknown scraper: #{slug.inspect}"
      klass_name.constantize
    end

    def self.available
      MAP.keys
    end
  end
end
