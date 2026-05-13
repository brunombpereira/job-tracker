require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq dashboard at /sidekiq — protected by basic auth in production.
  # Username/password set via SIDEKIQ_USERNAME / SIDEKIQ_PASSWORD env vars.
  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("SIDEKIQ_USERNAME", "")) &&
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_PASSWORD", ""))
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      resources :offers, only: %i[index show create update destroy] do
        member do
          patch :status
        end
        collection do
          post :import
          get :export, defaults: { format: :csv }
        end
        resources :notes, only: %i[create destroy]
      end

      resources :scraper_runs, only: %i[index create]
      resources :search_batches, only: %i[create show]

      get "stats", to: "stats#index"
    end
  end
end
