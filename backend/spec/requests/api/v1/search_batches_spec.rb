require "rails_helper"

RSpec.describe "Api::V1::SearchBatches", type: :request do
  include ActiveJob::TestHelper

  describe "POST /api/v1/search_batches" do
    let(:remotive_body) do
      {
        "jobs" => [ {
          "title"        => "Junior Ruby Developer",
          "company_name" => "Acme",
          "candidate_required_location" => "Worldwide",
          "url"          => "https://remotive.com/remote-jobs/acme-1",
          "description"  => "Build great APIs.",
          "publication_date" => "2026-05-13T10:00:00Z"
        } ]
      }.to_json
    end

    before do
      stub_request(:get, %r{remotive\.com}).to_return(
        status: 200, body: remotive_body,
        headers: { "Content-Type" => "application/json" }
      )
      # Other sources fail predictably so partial-status tests stay clean.
      stub_request(:get, %r{landing\.jobs}).to_return(status: 502)
      stub_request(:get, %r{weworkremotely\.com}).to_return(status: 502)
      stub_request(:get, %r{net-empregos\.com}).to_return(status: 502)
      stub_request(:get, %r{teamlyzer\.com}).to_return(status: 502)
      stub_request(:get, %r{linkedin\.com}).to_return(status: 502)
    end

    it "creates a batch with only the requested sources and runs them" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches", params: { sources: [ "remotive" ] }, as: :json
      end

      expect(response).to have_http_status(:accepted)
      body = JSON.parse(response.body)
      expect(body).to include("id", "status", "sources_requested")
      expect(body["sources_requested"]).to eq([ "remotive" ])

      batch = SearchBatch.find(body["id"]).reload
      expect(batch.scraper_runs.size).to eq(1)
      expect(batch.scraper_runs.first.source_name).to eq("remotive")
      expect(batch.status).to eq("succeeded")
      expect(batch.offers_created).to eq(1)
    end

    it "rejects unknown source names with 422" do
      post "/api/v1/search_batches", params: { sources: [ "bogus" ] }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to match(/Unknown sources/)
    end

    it "uses registry default_params when none are supplied" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches", params: { sources: [ "remotive" ] }, as: :json
      end
      run = SearchBatch.last.scraper_runs.first
      expect(run.params).to include("category" => "software-dev")
    end

    it "honors per-source override params" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches",
             params: { sources: [ "remotive" ], params_by_source: { remotive: { category: "devops" } } },
             as: :json
      end
      run = SearchBatch.last.scraper_runs.first
      expect(run.params).to include("category" => "devops")
    end

    it "results in partial status when one source fails and another succeeds" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches",
             params: { sources: %w[remotive weworkremotely] }, as: :json
      end

      batch = SearchBatch.last.reload
      statuses = batch.scraper_runs.pluck(:source_name, :status).to_h
      expect(statuses["remotive"]).to eq("succeeded")
      expect(statuses["weworkremotely"]).to eq("failed")
      expect(batch.status).to eq("partial")
    end
  end

  describe "GET /api/v1/search_batches/:id" do
    it "returns the batch with embedded run details" do
      batch = SearchBatch.create!(status: "succeeded", sources_requested: %w[remotive])
      ScraperRun.create!(source_name: "remotive", status: "succeeded",
                         offers_found: 3, offers_created: 2, offers_skipped: 1,
                         search_batch: batch)

      get "/api/v1/search_batches/#{batch.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("succeeded")
      expect(body["runs"].size).to eq(1)
      expect(body["runs"].first["source_name"]).to eq("remotive")
      expect(body["runs"].first["offers_created"]).to eq(2)
    end
  end
end
