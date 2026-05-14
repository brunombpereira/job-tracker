module Scrapers
  # Read model summarising scraper reliability — one entry per registered
  # source, built from recent ScraperRun history.
  #
  # It keys on offers_FOUND, not offers_created: a healthy scraper can
  # legitimately create 0 offers when everything it found is already in
  # the DB (offers_skipped high). But a source that returns found: 0 when
  # it used to find offers means its HTML selectors / feed broke — and
  # HTML scrapers break silently whenever a site changes its markup.
  class Health
    # How many of the most recent runs to examine per source.
    WINDOW = 10

    # Consecutive-signal thresholds for escalating a source's status.
    DOWN_FAILURES = 2
    DOWN_ZEROS    = 3

    Entry = Struct.new(
      :key, :display_name, :color, :status, :last_run_at, :last_status,
      :last_found, :consecutive_failures, :consecutive_zero_finds,
      keyword_init: true
    ) do
      def as_json(*)
        {
          key: key,
          display_name: display_name,
          color: color,
          status: status,
          last_run_at: last_run_at,
          last_status: last_status,
          last_found: last_found,
          consecutive_failures: consecutive_failures,
          consecutive_zero_finds: consecutive_zero_finds
        }
      end
    end

    def self.report
      new.report
    end

    # @return [Array<Entry>] one entry per registered source, in registry order
    def report
      runs_by_source = ScraperRun
        .where(source_name: Registry.available)
        .order(created_at: :desc)
        .group_by(&:source_name)

      Registry.public_list.map do |source|
        entry_for(source, runs_by_source.fetch(source[:key], []).first(WINDOW))
      end
    end

    private

    def entry_for(source, window)
      last = window.first
      failures = leading_count(window) { |r| r.status == "failed" }
      zeros    = leading_count(window) { |r| zero_find?(r) }

      Entry.new(
        key: source[:key],
        display_name: source[:display_name],
        color: source[:color],
        last_run_at: last&.created_at,
        last_status: last&.status,
        last_found: last&.offers_found,
        consecutive_failures: failures,
        consecutive_zero_finds: zeros,
        status: classify(window, failures, zeros)
      )
    end

    # Counts how many runs from the most recent backwards satisfy the
    # block, stopping at the first that doesn't.
    def leading_count(window)
      window.take_while { |run| yield(run) }.size
    end

    def zero_find?(run)
      run.status == "succeeded" && run.offers_found.to_i.zero?
    end

    def classify(window, failures, zeros)
      return :unknown if window.empty?
      return :down     if failures >= DOWN_FAILURES || zeros >= DOWN_ZEROS
      return :degraded if failures.positive? || zeros.positive?

      :ok
    end
  end
end
