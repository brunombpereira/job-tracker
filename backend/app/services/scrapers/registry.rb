module Scrapers
  # Single source of truth for what scrapers exist and their metadata. The
  # SearchBatchesController fans out to ALL registered sources whose
  # credentials are present; the cron and the manual-trigger UI both look up
  # client classes here.
  #
  # Class names stored as strings + .constantize at call time so Zeitwerk
  # doesn't load every client when this file is autoloaded.
  module Registry
    Source = Struct.new(
      :key, :display_name, :client_class_name, :color,
      :default_params, :env_required, :tag,
      keyword_init: true
    ) do
      def client_class
        client_class_name.constantize
      end

      # Returns true when every required ENV var is present. Sources that
      # need no credentials (RSS, public APIs) are always ready.
      def ready?
        env_required.all? { |k| ENV[k].to_s.strip != "" }
      end

      def as_json(*)
        {
          key:            key,
          display_name:   display_name,
          color:          color,
          tag:            tag,
          ready:          ready?,
          requires_env:   env_required,
          default_params: default_params
        }
      end
    end

    SOURCES = [
      Source.new(
        key: "remotive", display_name: "Remotive", tag: "API",
        client_class_name: "Scrapers::RemotiveClient",
        color: "#3da5d9",
        default_params: { category: "software-dev" },
        env_required: []
      ),
      Source.new(
        key: "landing_jobs", display_name: "Landing.jobs", tag: "API",
        client_class_name: "Scrapers::LandingJobsClient",
        color: "#7b2cbf",
        # Bumped from 50 → 100 so a broader slice of recent listings
        # gets ranked rather than truncated.
        default_params: { limit: 100 },
        env_required: []
      ),
      Source.new(
        key: "weworkremotely", display_name: "We Work Remotely", tag: "RSS",
        client_class_name: "Scrapers::WeworkremotelyClient",
        color: "#2d6a4f",
        default_params: { category: "remote-programming-jobs" },
        env_required: []
      ),
      Source.new(
        key: "net_empregos", display_name: "Net-Empregos", tag: "HTML",
        client_class_name: "Scrapers::NetEmpregosClient",
        color: "#1d3557",
        # Net-Empregos runs ~88 pages of 18 Programação listings. We
        # paginate the HTML category listing — 20 pages → ~360 of the
        # freshest. Pass `pages: N` (1–50) to widen or narrow.
        default_params: { pages: 20 },
        env_required: []
      ),
      Source.new(
        key: "teamlyzer", display_name: "Teamlyzer", tag: "HTML",
        client_class_name: "Scrapers::TeamlyzerClient",
        color: "#e07a5f",
        # 3 pages × ~20 cards = ~60 listings vs the previous single-page
        # ~20. Bump `pages` to widen, max 5.
        default_params: { pages: 3 },
        env_required: []
      ),
      Source.new(
        key: "linkedin", display_name: "LinkedIn", tag: "HTML",
        client_class_name: "Scrapers::LinkedinGuestClient",
        color: "#0a66c2",
        # The guest API has no profile awareness, so the keyword string
        # is the only lever on relevance. Run a few narrow queries aimed
        # at the profile (junior + the primary stacks) instead of one
        # broad "developer" net; results are unioned and deduped.
        # `location` is intentionally omitted — guest search runs
        # worldwide unless a location is passed explicitly.
        default_params: {
          keywords: [ "junior developer", "ruby on rails developer", "react developer" ],
          time: "month",
          pages: 4
        },
        env_required: []
      )
    ].freeze

    INDEX = SOURCES.index_by(&:key).freeze

    def self.client_for(slug)
      source = INDEX[slug.to_s] or
        raise ArgumentError, "Unknown scraper: #{slug.inspect}"
      source.client_class
    end

    def self.find(slug)
      INDEX[slug.to_s]
    end

    # All registered source keys, including those missing credentials.
    def self.available
      SOURCES.map(&:key)
    end

    # Source keys whose credentials are present and can be dispatched now.
    def self.ready
      SOURCES.select(&:ready?).map(&:key)
    end

    def self.public_list
      SOURCES.map(&:as_json)
    end
  end
end
