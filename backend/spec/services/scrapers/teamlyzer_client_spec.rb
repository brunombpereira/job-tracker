require "rails_helper"

RSpec.describe Scrapers::TeamlyzerClient do
  let(:html) do
    <<~HTML
      <html><body>
        <div class="row jobboard-ad" data-company="intellias">
          <div class="col-lg-12"><div class="panel jobcard">
            <a href="/companies/intellias">Intellias logo</a>
            <div class="jobcard__body">
              <span class="role-tag backend">Backend</span>
              <div class="jobcard__title-row">
                <h4 class="jobcard__title">
                  <a href="/companies/get-job/a15a532a-440f-456d-8dee-1417f6ef1af3?v=jobboard">Junior software engineer</a>
                </h4>
              </div>
              <div class="jobcard__meta">
                <a class="jobcard__company" href="/companies/intellias">Intellias</a>
              </div>
            </div>
          </div></div>
        </div>
        <div class="row jobboard-ad" data-company="imaginary-cloud">
          <div class="panel jobcard">
            <div class="jobcard__body">
              <span class="role-tag frontend">Frontend</span>
              <h4 class="jobcard__title">
                <a href="/companies/get-job/22222222-2222-2222-2222-222222222222?v=jobboard">Frontend dev</a>
              </h4>
              <a class="jobcard__company" href="/companies/imaginary-cloud">Imaginary Cloud</a>
            </div>
          </div>
        </div>
      </body></html>
    HTML
  end

  before do
    stub_request(:get, "https://pt.teamlyzer.com/companies/jobs")
      .to_return(status: 200, body: html, headers: { "Content-Type" => "text/html" })
  end

  it "creates one Offer per jobcard with full URL and role tag in stack" do
    expect { described_class.run }.to change(Offer, :count).by(2)
    senior = Offer.find_by(url: "https://pt.teamlyzer.com/companies/get-job/a15a532a-440f-456d-8dee-1417f6ef1af3?v=jobboard")
    expect(senior.title).to eq("Junior software engineer")
    expect(senior.company).to eq("Intellias")
    expect(senior.stack).to eq(["Backend"])
  end

  it "filters by keywords on title/company" do
    result = described_class.run(keywords: "frontend")
    expect(result[:created]).to eq(1)
    expect(Offer.last.title).to eq("Frontend dev")
  end

  it "raises FetchError on HTTP failure" do
    stub_request(:get, %r{teamlyzer\.com}).to_return(status: 500)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 500/)
  end
end
