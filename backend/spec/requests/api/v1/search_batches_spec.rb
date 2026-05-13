require "rails_helper"

RSpec.describe "Api::V1::SearchBatches", type: :request do
  include ActiveJob::TestHelper

  describe "POST /api/v1/search_batches" do
    let(:rss_body) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>ITJobs.pt</title>
            <item>
              <title>Ruby Dev — Co</title>
              <link>https://www.itjobs.pt/oferta/x1</link>
              <description>Localização: Porto</description>
              <pubDate>Tue, 13 May 2026 09:00:00 +0000</pubDate>
              <guid>https://www.itjobs.pt/oferta/x1</guid>
            </item>
          </channel>
        </rss>
      XML
    end

    before do
      # Stub the network so jobs run inline cleanly. We stub the role-feed
      # URL because the ITJobs default_params provide `role`.
      stub_request(:get, %r{itjobs\.pt}).to_return(status: 200, body: rss_body)
      # Any other source's network calls — return 502 so they fail predictably.
      stub_request(:get, %r{remotive\.com}).to_return(status: 502)
      stub_request(:get, %r{landing\.jobs}).to_return(status: 502)
      stub_request(:get, %r{weworkremotely\.com}).to_return(status: 502)
      stub_request(:get, %r{hacker-news\.firebaseio\.com}).to_return(status: 502)
      stub_request(:get, %r{net-empregos\.com}).to_return(status: 502)
      stub_request(:get, %r{teamlyzer\.com}).to_return(status: 502)
    end

    it "creates a batch with only the requested sources and runs them" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches", params: { sources: ["itjobs"] }, as: :json
      end

      expect(response).to have_http_status(:accepted)
      body = JSON.parse(response.body)
      expect(body).to include("id", "status", "sources_requested")
      expect(body["sources_requested"]).to eq(["itjobs"])

      batch = SearchBatch.find(body["id"]).reload
      expect(batch.scraper_runs.size).to eq(1)
      expect(batch.scraper_runs.first.source_name).to eq("itjobs")
      expect(batch.status).to eq("succeeded")
      expect(batch.offers_created).to eq(1)
    end

    it "rejects unknown source names with 422" do
      post "/api/v1/search_batches", params: { sources: ["bogus"] }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to match(/Unknown sources/)
    end

    it "uses registry default_params when none are supplied" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches", params: { sources: ["itjobs"] }, as: :json
      end
      run = SearchBatch.last.scraper_runs.first
      expect(run.params).to include("role" => "engenharia-informatica")
    end

    it "honors per-source override params" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches",
             params: { sources: ["itjobs"], params_by_source: { itjobs: { role: "back-end" } } },
             as: :json
      end
      run = SearchBatch.last.scraper_runs.first
      expect(run.params).to include("role" => "back-end")
    end

    it "results in partial status when one source fails and another succeeds" do
      perform_enqueued_jobs do
        post "/api/v1/search_batches",
             params: { sources: %w[itjobs remotive] }, as: :json
      end

      batch = SearchBatch.last.reload
      statuses = batch.scraper_runs.pluck(:source_name, :status).to_h
      expect(statuses["itjobs"]).to eq("succeeded")
      expect(statuses["remotive"]).to eq("failed")
      expect(batch.status).to eq("partial")
    end
  end

  describe "GET /api/v1/search_batches/:id" do
    it "returns the batch with embedded run details" do
      batch = SearchBatch.create!(status: "succeeded", sources_requested: %w[adzuna])
      ScraperRun.create!(source_name: "adzuna", status: "succeeded",
                         offers_found: 3, offers_created: 2, offers_skipped: 1,
                         search_batch: batch)

      get "/api/v1/search_batches/#{batch.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("succeeded")
      expect(body["runs"].size).to eq(1)
      expect(body["runs"].first["source_name"]).to eq("adzuna")
      expect(body["runs"].first["offers_created"]).to eq(2)
    end
  end
end
