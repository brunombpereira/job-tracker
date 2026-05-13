require "rails_helper"

RSpec.describe Scrapers::WeworkremotelyClient do
  let(:rss) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>WWR</title>
          <item>
            <title>Route: Junior Designer</title>
            <link>https://weworkremotely.com/remote-jobs/route-junior-designer</link>
            <description>&lt;p&gt;Design things remotely.&lt;/p&gt;</description>
            <pubDate>Tue, 13 May 2026 09:00:00 +0000</pubDate>
            <guid>https://weworkremotely.com/remote-jobs/route-junior-designer</guid>
          </item>
          <item>
            <title>Acme Inc: Ruby Engineer</title>
            <link>https://weworkremotely.com/remote-jobs/acme-ruby</link>
            <description>Ruby</description>
            <pubDate>Mon, 12 May 2026 09:00:00 +0000</pubDate>
            <guid>https://weworkremotely.com/remote-jobs/acme-ruby</guid>
          </item>
        </channel>
      </rss>
    XML
  end

  before do
    stub_request(:get, %r{weworkremotely\.com/categories/remote-programming-jobs\.rss})
      .to_return(status: 200, body: rss)
  end

  it "splits `Company: Title` and marks all as remoto" do
    described_class.run
    o = Offer.find_by(url: "https://weworkremotely.com/remote-jobs/route-junior-designer")
    expect(o.title).to eq("Junior Designer")
    expect(o.company).to eq("Route")
    expect(o.modality).to eq("remoto")
    expect(o.location).to eq("Remote")
  end

  it "honors the category param" do
    stub_request(:get, %r{categories/remote-ruby-jobs\.rss}).to_return(status: 200, body: rss)
    described_class.run(category: "remote-ruby-jobs")
    expect(WebMock).to have_requested(:get, %r{remote-ruby-jobs\.rss})
  end

  it "raises FetchError on HTTP failure" do
    stub_request(:get, %r{weworkremotely\.com}).to_return(status: 502)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 502/)
  end
end
