module Api
  module V1
    class NotesController < ApplicationController
      before_action :set_offer

      # POST /api/v1/offers/:offer_id/notes
      def create
        # Use create! (not require) so an empty content surfaces as a
        # RecordInvalid → 422 via ApplicationController#record_invalid,
        # with per-field errors. ParameterMissing would return 400.
        note = @offer.notes.create!(content: params[:content])
        render json: note, status: :created
      end

      # DELETE /api/v1/offers/:offer_id/notes/:id
      def destroy
        note = @offer.notes.find(params[:id])
        note.destroy!
        head :no_content
      end

      private

      def set_offer
        @offer = Offer.find(params[:offer_id])
      end
    end
  end
end
