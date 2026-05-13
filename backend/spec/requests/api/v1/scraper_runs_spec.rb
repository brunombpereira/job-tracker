require "rails_helper"

RSpec.describe "Api::V1::ScraperRuns", type: :request do
  describe "GET /api/v1/scraper_runs" do
    it "returns the registered sources and recent runs" do
      ScraperRun.create!(source_name: "adzuna", status: "succeeded", offers_found: 10)
      ScraperRun.create!(source_name: "itjobs", status: "failed", error_message: "boom")

      get "/api/v1/scraper_runs"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["sources"]).to match_array(%w[adzuna itjobs])
      expect(body["runs"].size).to eq(2)
      expect(body["runs"].first).to include("source_name", "status")
    end
  end

  describe "POST /api/v1/scraper_runs" do
    it "rejects unknown sources with 422" do
      post "/api/v1/scraper_runs", params: { source: "nope" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "enqueues the job for valid sources" do
      expect {
        post "/api/v1/scraper_runs", params: { source: "itjobs", params: { role: "back-end" } }
      }.to have_enqueued_job(ScraperRunJob).with("itjobs", hash_including("role" => "back-end"))

      expect(response).to have_http_status(:accepted)
    end
  end
end
