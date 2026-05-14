require "rails_helper"

RSpec.describe "Api::V1::ScraperRuns", type: :request do
  describe "GET /api/v1/scraper_runs" do
    it "returns the registered sources and recent runs" do
      ScraperRun.create!(source_name: "remotive", status: "succeeded", offers_found: 10)
      ScraperRun.create!(source_name: "weworkremotely", status: "failed", error_message: "boom")

      get "/api/v1/scraper_runs"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["sources"]).to include("remotive", "weworkremotely")
      expect(body["sources"].size).to be >= 2
      expect(body["runs"].size).to eq(2)
      expect(body["runs"].first).to include("source_name", "status")
    end
  end

  describe "GET /api/v1/scraper_runs/health" do
    it "returns a health entry per registered source" do
      ScraperRun.create!(source_name: "linkedin", status: "failed", error_message: "boom")
      ScraperRun.create!(source_name: "linkedin", status: "failed", error_message: "boom")

      get "/api/v1/scraper_runs/health"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["sources"].size).to eq(Scrapers::Registry.available.size)

      linkedin = body["sources"].find { |s| s["key"] == "linkedin" }
      expect(linkedin["status"]).to eq("down")
      expect(linkedin["consecutive_failures"]).to eq(2)

      untouched = body["sources"].find { |s| s["key"] == "remotive" }
      expect(untouched["status"]).to eq("unknown")
    end
  end

  describe "POST /api/v1/scraper_runs" do
    it "rejects unknown sources with 422" do
      post "/api/v1/scraper_runs", params: { source: "nope" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "enqueues the job for valid sources" do
      expect {
        post "/api/v1/scraper_runs", params: { source: "remotive", params: { category: "software-dev" } }
      }.to have_enqueued_job(ScraperRunJob).with("remotive", hash_including("category" => "software-dev"))

      expect(response).to have_http_status(:accepted)
    end
  end
end
