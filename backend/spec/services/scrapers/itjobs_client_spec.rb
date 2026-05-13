require "rails_helper"

RSpec.describe Scrapers::ItjobsClient do
  let(:rss_body) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>ITJobs.pt</title>
          <link>https://www.itjobs.pt</link>
          <item>
            <title>Senior Ruby on Rails Developer (m/f) — Wiremaze</title>
            <link>https://www.itjobs.pt/oferta/12345</link>
            <description>&lt;p&gt;Localização: Porto. Remoto possível.&lt;/p&gt;</description>
            <pubDate>Tue, 13 May 2026 09:00:00 +0000</pubDate>
            <guid>https://www.itjobs.pt/oferta/12345</guid>
          </item>
          <item>
            <title>Junior Backend Engineer — Acme Inc</title>
            <link>https://www.itjobs.pt/oferta/12346</link>
            <description>Localização: Lisboa</description>
            <pubDate>Mon, 12 May 2026 09:00:00 +0000</pubDate>
            <guid>https://www.itjobs.pt/oferta/12346</guid>
          </item>
        </channel>
      </rss>
    XML
  end

  describe "#run" do
    before do
      stub_request(:get, "https://www.itjobs.pt/feed").to_return(status: 200, body: rss_body)
    end

    it "creates an Offer per entry" do
      expect { described_class.run }.to change(Offer, :count).by(2)
    end

    it "splits title into title + company" do
      described_class.run
      offer = Offer.find_by(url: "https://www.itjobs.pt/oferta/12345")
      expect(offer.title).to eq("Senior Ruby on Rails Developer (m/f)")
      expect(offer.company).to eq("Wiremaze")
    end

    it "extracts Localização from description" do
      described_class.run
      offer = Offer.find_by(url: "https://www.itjobs.pt/oferta/12346")
      expect(offer.location).to eq("Lisboa")
    end

    it "dedupes by url on re-run" do
      described_class.run
      expect { described_class.run }.not_to change(Offer, :count)
    end

    it "uses /role/<slug> endpoint when role param given" do
      stub_request(:get, "https://www.itjobs.pt/api/feed/role/back-end")
        .to_return(status: 200, body: rss_body)
      described_class.run(role: "back-end")
      assert_requested(:get, "https://www.itjobs.pt/api/feed/role/back-end")
    end
  end
end
