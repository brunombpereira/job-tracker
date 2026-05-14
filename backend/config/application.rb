require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JobTracker
  class Application < Rails::Application
    config.load_defaults 7.1

    # API-only mode
    config.api_only = true

    # Time zone
    config.time_zone = "Europe/Lisbon"

    # Autoload paths
    config.autoload_lib(ignore: %w[assets tasks])

    # Root for personal profile artefacts (CV PDFs, cover-letter
    # templates) consumed by ProfileController and CoverLetterGenerator.
    # These files live outside the repo (see .gitignore); the test env
    # repoints this at committed fixtures.
    config.x.profile_storage = Rails.root.join("storage", "profile")
  end
end
