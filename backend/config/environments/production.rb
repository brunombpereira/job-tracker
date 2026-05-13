require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.cache_store = :solid_cache_store if defined?(SolidCache)

  config.active_job.queue_adapter = :async
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true") == "true"

  # Allow Render's *.onrender.com hosts plus anything in the ALLOWED_HOSTS env
  # var (CSV). Hosts blocking is a Rails 7+ security default.
  config.hosts << /.*\.onrender\.com/
  ENV.fetch("ALLOWED_HOSTS", "").split(",").map(&:strip).each do |h|
    next if h.empty?
    config.hosts << h
  end
end
