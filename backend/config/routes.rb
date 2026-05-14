require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq dashboard at /sidekiq — protected by basic auth in production.
  # Username/password set via SIDEKIQ_USERNAME / SIDEKIQ_PASSWORD env vars.
  # Fails closed: if either env var is unset, every request is denied
  # (otherwise blank credentials would secure_compare("", "") => true).
  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      expected_user = ENV["SIDEKIQ_USERNAME"].to_s
      expected_password = ENV["SIDEKIQ_PASSWORD"].to_s
      if expected_user.empty? || expected_password.empty?
        false
      else
        ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &&
          ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
      end
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      resources :offers, only: %i[index show create update destroy] do
        member do
          patch :status
          post :fetch_description
        end
        collection do
          post :import
          post :import_url
          delete :destroy_all
          get :export, defaults: { format: :csv }
        end
        resources :notes, only: %i[create destroy]
      end

      # Shared-secret auth probe — see ApplicationController#authenticate_request!
      get "auth", to: "auth#show"

      resources :scraper_runs, only: %i[index create] do
        collection { get :health }
      end
      resources :search_batches, only: %i[index create show]
      resources :sources, only: %i[index]

      # The editable profile (personal details + scoring keywords).
      get   "profile", to: "profile#show"
      patch "profile", to: "profile#update"

      # Personal CV + cover letter artefacts.
      get "profile/files",         to: "profile#files"
      get "profile/cv",            to: "profile#cv"
      get "profile/cover_letter",  to: "profile#cover_letter"
      post   "profile/documents",       to: "profile#upload"
      delete "profile/documents/:kind", to: "profile#destroy_document"

      get "stats", to: "stats#index"
    end
  end
end
