Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

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
      end

      get "stats", to: "stats#index"
    end
  end
end
