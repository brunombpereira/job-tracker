require "rails_helper"

RSpec.describe Scrapers::LandingJobsClient do
  let(:body) do
    [
      {
        "id"           => 19019,
        "title"        => "DevOps Engineer",
        "company_id"   => 7766,
        "type"         => "Full-time",
        "remote"       => false,
        "url"          => "https://landing.jobs/at/cliftonlarsonallen/devops-engineer-in-lisbon-2025-1",
        "role_description" => "<div>Build cloud stuff.</div>",
        "published_at"     => "2026-03-03T11:55:01.551Z",
        "gross_salary_low"  => 50000,
        "gross_salary_high" => 73000,
        "currency_code"     => "EUR",
        "tags"     => %w[Azure CI/CD Python],
        "locations" => [ { "city" => "Lisbon", "country_code" => "PT" } ]
      },
      {
        "id"           => 19020,
        "title"        => "Frontend Developer",
        "url"          => "https://landing.jobs/at/some-startup/frontend-2",
        "remote"       => true,
        "role_description" => "Frontend stuff.",
        "published_at"     => "2026-05-01T00:00:00Z",
        "tags"     => %w[React TypeScript],
        "locations" => []
      }
    ]
  end

  before do
    stub_request(:get, %r{landing\.jobs/api/v1/jobs})
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "derives company from the /at/{slug}/ URL segment" do
    described_class.run
    first = Offer.find_by(url: "https://landing.jobs/at/cliftonlarsonallen/devops-engineer-in-lisbon-2025-1")
    expect(first.company).to eq("Cliftonlarsonallen")
  end

  let(:devops_url) { "https://landing.jobs/at/cliftonlarsonallen/devops-engineer-in-lisbon-2025-1" }
  let(:frontend_url) { "https://landing.jobs/at/some-startup/frontend-2" }

  it "marks modality based on the remote flag" do
    described_class.run
    expect(Offer.find_by(url: devops_url).modality).to eq("presencial")
    expect(Offer.find_by(url: frontend_url).modality).to eq("remoto")
  end

  it "formats salary as €Xk–€Yk when low+high present" do
    described_class.run
    expect(Offer.find_by(url: devops_url).salary_range).to eq("€50k–€73k")
  end

  it "stores tags as the Offer stack array" do
    described_class.run
    expect(Offer.find_by(url: devops_url).stack).to include("Azure", "CI/CD", "Python")
  end

  it "formats location from the first locations entry" do
    described_class.run
    expect(Offer.find_by(url: devops_url).location).to eq("Lisbon, PT")
  end

  it "raises FetchError on HTTP failure" do
    stub_request(:get, %r{landing\.jobs}).to_return(status: 503)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 503/)
  end
end
