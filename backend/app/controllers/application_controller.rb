class ApplicationController < ActionController::API
  include Pagy::Backend
  # API mode strips MimeResponds — re-include it so #respond_to works for
  # endpoints that need to serve CSV or XLSX alongside the default JSON.
  include ActionController::MimeResponds

  before_action :authenticate_request!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid,  with: :record_invalid

  private

  # Single-user shared-secret gate. When API_ACCESS_TOKEN is set, every
  # request must carry it as `Authorization: Bearer <token>`. When the
  # env var is unset the API is open — intended for local dev and the
  # test suite; production logs a warning at boot when it's missing
  # (see config/initializers/api_access.rb).
  def authenticate_request!
    return unless api_token_configured?
    return if valid_api_token?

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def api_token_configured?
    ENV["API_ACCESS_TOKEN"].present?
  end

  def valid_api_token?
    provided = request.authorization.to_s.sub(/\ABearer /i, "")
    ActiveSupport::SecurityUtils.secure_compare(provided, ENV["API_ACCESS_TOKEN"].to_s)
  end

  def record_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def record_invalid(error)
    render json: {
      error:          error.message,
      errors:         error.record.errors.messages,         # { field: [msg, ...] }
      full_messages:  error.record.errors.full_messages
    }, status: :unprocessable_entity
  end
end
