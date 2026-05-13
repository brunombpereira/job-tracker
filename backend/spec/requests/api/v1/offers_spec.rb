require "rails_helper"

RSpec.describe "Api::V1::Offers", type: :request do
  describe "GET /api/v1/offers" do
    let!(:offers) { create_list(:offer, 3) }

    it "returns paginated list" do
      get "/api/v1/offers"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(3)
      expect(response.headers["Total-Count"]).to eq("3")
    end

    it "filters by status" do
      create(:offer, :applied)

      get "/api/v1/offers", params: { status: "applied" }

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["status"]).to eq("applied")
    end

    it "filters by match_score_gte" do
      create(:offer, :high_match)

      get "/api/v1/offers", params: { match_score_gte: 5 }

      body = JSON.parse(response.body)
      expect(body.size).to be >= 1
      body.each { |o| expect(o["match_score"]).to be >= 5 }
    end
  end

  describe "POST /api/v1/offers" do
    let(:valid_params) do
      { offer: { title: "Junior Dev", company: "Acme", location: "Porto", modality: "hibrido" } }
    end

    it "creates an offer" do
      expect {
        post "/api/v1/offers", params: valid_params
      }.to change(Offer, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns errors on invalid input" do
      post "/api/v1/offers", params: { offer: { title: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/offers/:id/status" do
    let(:offer) { create(:offer, status: "new") }

    it "updates status and records change" do
      expect {
        patch "/api/v1/offers/#{offer.id}/status", params: { status: "interested" }
      }.to change { offer.reload.status_changes.count }.by(1)

      expect(offer.reload.status).to eq("interested")
    end
  end
end
