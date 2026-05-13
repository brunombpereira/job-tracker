require "rails_helper"

RSpec.describe Scrapers::LinkedinGuestClient do
  let(:html) do
    <<~HTML
      <html><body>
      <li>
        <div class="base-card relative base-search-card base-search-card--link job-search-card" data-entity-urn="urn:li:jobPosting:1111">
          <a class="base-card__full-link" href="https://pt.linkedin.com/jobs/view/junior-backend-1111?position=1&amp;refId=abc"></a>
          <div class="base-search-card__info">
            <h3 class="base-search-card__title">Junior Backend Developer</h3>
            <h4 class="base-search-card__subtitle">
              <a href="https://pt.linkedin.com/company/acme">Acme · Software</a>
            </h4>
            <div class="base-search-card__metadata">
              <span class="job-search-card__location">Aveiro, Portugal</span>
              <time datetime="2026-05-10">2 days ago</time>
            </div>
          </div>
        </div>
      </li>
      <li>
        <div class="base-card base-search-card" data-entity-urn="urn:li:jobPosting:2222">
          <a class="base-card__full-link" href="https://pt.linkedin.com/jobs/view/frontend-2222"></a>
          <div class="base-search-card__info">
            <h3 class="base-search-card__title">Frontend Engineer (Remote)</h3>
            <h4 class="base-search-card__subtitle">
              <a href="#">Globex</a>
            </h4>
            <div class="base-search-card__metadata">
              <span class="job-search-card__location">Portugal (Remote)</span>
              <time datetime="2026-05-11">1 day ago</time>
            </div>
          </div>
        </div>
      </li>
      </body></html>
    HTML
  end

  before do
    stub_request(:get, %r{linkedin\.com/jobs-guest/jobs/api/seeMoreJobPostings/search})
      .to_return(status: 200, body: html, headers: { "Content-Type" => "text/html" })
  end

  it "creates one Offer per card with cleaned URL and parsed metadata" do
    expect { described_class.run }.to change(Offer, :count).by(2)

    backend = Offer.find_by(url: "https://pt.linkedin.com/jobs/view/junior-backend-1111")
    expect(backend.title).to eq("Junior Backend Developer")
    expect(backend.company).to eq("Acme · Software")
    expect(backend.location).to eq("Aveiro, Portugal")
    expect(backend.posted_date).to eq(Date.new(2026, 5, 10))
  end

  it "infers remote modality from the location/title text" do
    described_class.run
    frontend = Offer.find_by(url: "https://pt.linkedin.com/jobs/view/frontend-2222")
    expect(frontend.modality).to eq("remoto")
  end

  it "strips the ?position=&refId=&trackingId=… query so dedupe works across runs" do
    described_class.run
    expect(Offer.first.url).not_to include("?")
  end

  it "honors keyword/location/time params on the endpoint" do
    described_class.run(keywords: "rails dev", location: "Porto", time: "week")
    expect(WebMock).to have_requested(:get, %r{linkedin\.com/jobs-guest/jobs/api/seeMoreJobPostings/search})
      .with(query: hash_including("keywords" => "rails dev", "location" => "Porto", "f_TPR" => "r604800"))
  end

  it "raises FetchError on HTTP failure" do
    stub_request(:get, %r{linkedin\.com}).to_return(status: 451)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 451/)
  end
end
