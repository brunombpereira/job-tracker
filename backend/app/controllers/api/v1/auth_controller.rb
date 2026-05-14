module Api
  module V1
    # Reports whether the API requires a shared-secret token and whether
    # the current request carries a valid one. Skips the auth filter so
    # the frontend can probe lock state before it has a token.
    class AuthController < ApplicationController
      skip_before_action :authenticate_request!

      # GET /api/v1/auth
      def show
        render json: {
          required:      api_token_configured?,
          authenticated: !api_token_configured? || valid_api_token?
        }
      end
    end
  end
end
