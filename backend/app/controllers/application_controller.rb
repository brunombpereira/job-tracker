class ApplicationController < ActionController::API
  include Pagy::Backend
  # API mode strips MimeResponds — re-include it so #respond_to works for
  # endpoints that need to serve CSV or XLSX alongside the default JSON.
  include ActionController::MimeResponds

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid,  with: :record_invalid

  private

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
