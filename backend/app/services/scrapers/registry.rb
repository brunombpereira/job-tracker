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
        key: "net_empregos", display_name: "Net-Empregos", tag: "RSS",
        client_class_name: "Scrapers::NetEmpregosClient",
        color: "#1d3557",
        # "Informática" matches all four sub-categories (Programação,
        # Análise, Gestão de Redes, Web/Multimédia) — broader net so
        # adjacent tech roles also land in the inbox and get ranked by
        # ProfileMatcher.
        default_params: { category: "Informática" },
        env_required: []
      ),
      Source.new(
        key: "teamlyzer", display_name: "Teamlyzer", tag: "HTML",
        client_class_name: "Scrapers::TeamlyzerClient",
        color: "#e07a5f",
        default_params: {},
        env_required: []
      ),
      Source.new(
        key: "linkedin", display_name: "LinkedIn", tag: "HTML",
        client_class_name: "Scrapers::LinkedinGuestClient",
        color: "#0a66c2",
        # Broad net: every PT developer/engineer listing from the last
        # month. ProfileMatcher handles the junior-vs-senior sorting
        # afterwards — narrowing the query at LinkedIn level was hiding
        # adjacent roles ("Software Engineer", "Web Developer", etc.).
        default_params: { keywords: "developer", location: "Portugal", time: "month" },
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
