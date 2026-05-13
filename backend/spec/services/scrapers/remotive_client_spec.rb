require "rails_helper"

RSpec.describe Scrapers::RemotiveClient do
  let(:body) do
    {
      "jobs" => [
        {
          "title"        => "Backend Engineer (Ruby)",
          "company_name" => "Acme",
          "candidate_required_location" => "Worldwide",
          "url"          => "https://remotive.com/remote-jobs/backend/acme-1",
          "description"  => "<p>Build great APIs.</p>",
          "publication_date" => "2026-05-13T10:00:00Z",
          "salary"       => "$80k-$120k"
        },
        {
          "title"        => "Frontend Engineer",
          "company_name" => "Globex",
          "candidate_required_location" => "Europe Only",
          "url"          => "https://remotive.com/remote-jobs/frontend/globex-1",
          "description"  => "React + TS.",
          "publication_date" => "2026-05-12T10:00:00Z"
        }
      ]
    }
  end

  before do
    stub_request(:get, %r{remotive\.com/api/remote-jobs})
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "creates one Offer per result, tagged remoto" do
    result = nil
    expect { result = described_class.run(category: "software-dev") }
      .to change(Offer, :count).by(2)

    expect(result).to include(found: 2, created: 2, skipped: 0)
    expect(Offer.pluck(:modality).uniq).to eq(["remoto"])
  end

  it "passes the salary string through when present" do
    described_class.run
    first = Offer.find_by(url: "https://remotive.com/remote-jobs/backend/acme-1")
    expect(first.salary_range).to eq("$80k-$120k")
  end

  it "raises FetchError on non-2xx" do
    stub_request(:get, %r{remotive\.com}).to_return(status: 500)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 500/)
  end
end
