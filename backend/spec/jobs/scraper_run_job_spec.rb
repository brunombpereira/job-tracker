require "rails_helper"

RSpec.describe ScraperRunJob, type: :job do
  describe "#perform" do
    let(:rss_body) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>ITJobs.pt</title>
            <item>
              <title>Ruby Dev — Co</title>
              <link>https://www.itjobs.pt/oferta/1</link>
              <description>Localização: Porto</description>
              <pubDate>Tue, 13 May 2026 09:00:00 +0000</pubDate>
              <guid>https://www.itjobs.pt/oferta/1</guid>
            </item>
          </channel>
        </rss>
      XML
    end

    it "creates a ScraperRun, marks it succeeded, and stores counts" do
      stub_request(:get, "https://www.itjobs.pt/feed").to_return(status: 200, body: rss_body)

      expect { described_class.perform_now("itjobs") }
        .to change(ScraperRun, :count).by(1)

      run = ScraperRun.last
      expect(run.source_name).to eq("itjobs")
      expect(run.status).to eq("succeeded")
      expect(run.offers_found).to eq(1)
      expect(run.offers_created).to eq(1)
      expect(run.duration_seconds).to be >= 0
    end

    it "marks the run failed and re-raises when the scraper fails" do
      stub_request(:get, "https://www.itjobs.pt/feed").to_return(status: 502)

      expect {
        described_class.perform_now("itjobs")
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
