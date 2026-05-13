require "rails_helper"

RSpec.describe "Api::V1::Notes", type: :request do
  let(:offer) { create(:offer) }

  describe "POST /api/v1/offers/:offer_id/notes" do
    it "creates a note" do
      expect {
        post "/api/v1/offers/#{offer.id}/notes", params: { content: "First call went well" }
      }.to change { offer.notes.count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["content"]).to eq("First call went well")
    end

    it "returns 422 when content is missing" do
      post "/api/v1/offers/#{offer.id}/notes", params: { content: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/offers/:offer_id/notes/:id" do
    let!(:note) { offer.notes.create!(content: "delete me") }

    it "destroys the note" do
      expect {
        delete "/api/v1/offers/#{offer.id}/notes/#{note.id}"
      }.to change { offer.notes.count }.by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
