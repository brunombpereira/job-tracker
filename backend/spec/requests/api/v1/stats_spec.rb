require "rails_helper"

RSpec.describe "Api::V1::Stats", type: :request do
  describe "GET /api/v1/stats" do
    before do
      create(:offer, status: "new")
      create(:offer, status: "interested")
      create(:offer, status: "applied")
      create(:offer, :applied)
      create(:offer, :archived)
    end

    it "returns funnel + by_source + total counts" do
      get "/api/v1/stats"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body).to include("total", "funnel", "by_source", "updated_at", "recent_7d")
      expect(body["total"]).to eq(4) # archived is excluded
      expect(body["funnel"]["applied"]).to eq(2)
      expect(body["funnel"]["new"]).to eq(1)
    end
  end
end
