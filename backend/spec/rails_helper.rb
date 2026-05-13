require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("Rails is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "shoulda/matchers"
require "factory_bot_rails"
require "webmock/rspec"

# Block ALL real network access during tests; failed connections surface as
# WebMock::NetConnectNotAllowedError so we know exactly what to stub.
WebMock.disable_net_connect!(allow_localhost: true)

# ActiveJob inline so scraper job specs can drive the work synchronously.
require "sidekiq/testing"
Sidekiq::Testing.inline!

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Run ActiveJob inline so request specs that enqueue jobs can assert on
  # the side effects (without needing to also run Sidekiq).
  config.before(:each) { ActiveJob::Base.queue_adapter = :inline }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
