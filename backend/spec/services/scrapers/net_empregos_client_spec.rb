require "rails_helper"

RSpec.describe Scrapers::NetEmpregosClient do
  # Two-item HTML fixture matching the live `.job-item` template.
  def page_html(ids = [ 1 ])
    items = ids.map do |id|
      <<~ITEM
        <div class="job-item media">
          <div class="media-body">
            <h2><a class="oferta-link" href="/#{id}/junior-backend-developer-#{id}/">Junior Backend Developer #{id}</a></h2>
            <div class="row">
              <div class="col-2"></div>
              <div class="col-10">
                <div class="job-ad-item">
                  <ul>
                    <li><i class="flaticon-calendar"></i> 13-5-2026</li>
                    <li><i class="flaticon-pin"></i> Aveiro</li>
                    <li><i class="fa fa-tags"></i> Informática ( Programação )</li>
                    <li><i class="flaticon-work"></i> Acme Lda</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      ITEM
    end
    "<html><body>#{items.join}</body></html>"
  end

  before do
    # Page 1 → ids 1..3, page 2 → ids 4..5, page 3 → empty (end of pages).
    stub_request(:get, %r{net-empregos\.com/empregos-portugal-informatica-programacao\.asp})
      .with(query: hash_including("categoria" => "5"))
      .to_return do |req|
        page = req.uri.query_values["page"]&.to_i || 1
        case page
        when 1 then { status: 200, body: page_html([ 1, 2, 3 ]) }
        when 2 then { status: 200, body: page_html([ 4, 5 ]) }
        else        { status: 200, body: "<html><body></body></html>" }
        end
      end
  end

  it "paginates and dedupes across pages" do
    result = described_class.run(pages: 3)
    expect(result[:found]).to eq(5) # 3 + 2 (page 3 empty → stops)
    expect(result[:created]).to eq(5)
    expect(Offer.pluck(:url)).to include(
      "https://www.net-empregos.com/1/junior-backend-developer-1/",
      "https://www.net-empregos.com/4/junior-backend-developer-4/",
    )
  end

  it "stops paginating when a page returns nothing new" do
    result = described_class.run(pages: 5)
    # Still 5 — pages 3+ are empty, loop breaks early.
    expect(result[:found]).to eq(5)
  end

  it "parses Zona into location and the work icon into company" do
    described_class.run(pages: 1)
    offer = Offer.find_by(url: "https://www.net-empregos.com/1/junior-backend-developer-1/")
    expect(offer.company).to eq("Acme Lda")
    expect(offer.location).to eq("Aveiro")
    expect(offer.posted_date).to eq(Date.new(2026, 5, 13))
  end

  it "raises FetchError on HTTP failure" do
    stub_request(:get, %r{net-empregos\.com}).to_return(status: 503)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 503/)
  end
end
