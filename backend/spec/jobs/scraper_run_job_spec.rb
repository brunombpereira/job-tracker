require "rails_helper"

RSpec.describe ScraperRunJob, type: :job do
  describe "#perform" do
    let(:remotive_body) do
      {
        "jobs" => [{
          "title"        => "Junior Ruby Developer",
          "company_name" => "Acme",
          "candidate_required_location" => "Worldwide",
          "url"          => "https://remotive.com/remote-jobs/acme-1",
          "description"  => "Build great APIs.",
          "publication_date" => "2026-05-13T10:00:00Z"
        }]
      }
    end

    it "creates a ScraperRun, marks it succeeded, and stores counts" do
      stub_request(:get, %r{remotive\.com/api/remote-jobs}).to_return(
        status: 200, body: remotive_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect { described_class.perform_now("remotive") }
        .to change(ScraperRun, :count).by(1)

      run = ScraperRun.last
      expect(run.source_name).to eq("remotive")
      expect(run.status).to eq("succeeded")
      expect(run.offers_found).to eq(1)
      expect(run.offers_created).to eq(1)
      expect(run.duration_seconds).to be >= 0
    end

    it "marks the run failed and re-raises when the scraper fails" do
      stub_request(:get, %r{remotive\.com}).to_return(status: 502)

      expect {
        described_class.perform_now("remotive")
      }.to raise_error(Scrapers::BaseClient::FetchError)

      run = ScraperRun.last
      expect(run.status).to eq("failed")
      expect(run.error_message).to match(/HTTP 502/)
    end

    it "raises if source_name is unknown" do
      expect {
        described_class.perform_now("totally-fake-source")
      }.to raise_error(ArgumentError, /Unknown scraper/)
    end
  end
end
