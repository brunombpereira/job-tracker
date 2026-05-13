require "rails_helper"

RSpec.describe Scrapers::AdzunaClient do
  before do
    ENV["ADZUNA_APP_ID"]  = "test-id"
    ENV["ADZUNA_APP_KEY"] = "test-key"
  end

  after do
    ENV.delete("ADZUNA_APP_ID")
    ENV.delete("ADZUNA_APP_KEY")
  end

  let(:sample_response) do
    {
      "results" => [
        {
          "title"        => "Junior Ruby Developer",
          "company"      => { "display_name" => "Acme" },
          "location"     => { "display_name" => "Porto" },
          "redirect_url" => "https://example.com/jobs/1",
          "description"  => "<p>We want a Ruby dev. Remote OK.</p>",
          "created"      => "2026-05-13T10:00:00Z",
          "salary_min"   => 25000,
          "salary_max"   => 32000
        },
        {
          "title"        => "Senior Backend Engineer",
          "company"      => { "display_name" => "Globex" },
          "location"     => { "display_name" => "Lisboa" },
          "redirect_url" => "https://example.com/jobs/2",
          "description"  => "Backend role at Globex.",
          "created"      => "2026-05-12T10:00:00Z"
        }
      ]
    }
  end

  describe "#run" do
    before do
      stub_request(:get, %r{api\.adzuna\.com/v1/api/jobs/pt/search/1})
        .to_return(
          status: 200,
          body: sample_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates one Offer per unique result and dedupes by url" do
      # Pre-seed one to be skipped as duplicate
      Offer.create!(title: "Pre", company: "X", url: "https://example.com/jobs/1")

      result = nil
      expect { result = described_class.run(keywords: "ruby") }
        .to change(Offer, :count).by(1)

      expect(result[:found]).to eq(2)
      expect(result[:created]).to eq(1)
      expect(result[:skipped]).to eq(1)
    end

    it "ensures an Adzuna Source row exists and tags offers with it" do
      described_class.run(keywords: "ruby")
      source = Source.find_by(name: "Adzuna")
      expect(source).not_to be_nil
      expect(Offer.where(source_id: source.id).count).to eq(2)
    end

    it "infers modality from text" do
      described_class.run(keywords: "ruby")
      first = Offer.find_by(url: "https://example.com/jobs/1")
      expect(first.modality).to eq("remoto") # description says "Remote OK"
    end

    it "formats salary range when present" do
      described_class.run(keywords: "ruby")
      first = Offer.find_by(url: "https://example.com/jobs/1")
      expect(first.salary_range).to eq("€25k–€32k")
    end

    it "raises FetchError on HTTP failure" do
      stub_request(:get, %r{api\.adzuna\.com}).to_return(status: 500)
      expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 500/)
    end
  end
end
