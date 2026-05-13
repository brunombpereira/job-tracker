require "rails_helper"

RSpec.describe Scrapers::NetEmpregosClient do
  let(:rss) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:dc="https://purl.org/dc/elements/1.1/">
        <channel>
          <title>Net-Empregos</title>
          <item>
            <title><![CDATA[Backend Developer (m/f)]]></title>
            <dc:creator><![CDATA[Acme Lda]]></dc:creator>
            <link>https://www.net-empregos.com/15416450/backend-developer/</link>
            <description><![CDATA[&lt;b&gt;Empresa: &lt;/b&gt;Acme Lda&lt;br&gt;&lt;b&gt;Categoria: &lt;/b&gt;Informática ( Programação )&lt;br&gt;&lt;b&gt;Zona: &lt;/b&gt; Aveiro&lt;br&gt;&lt;b&gt;Data: &lt;/b&gt;13-5-2026&lt;br&gt;&lt;br&gt;&lt;b&gt;Descrição: &lt;/b&gt;Ruby/Rails dev em regime remoto.&lt;br&gt;&lt;br&gt;&lt;a target='_blank' href='https://www.net-empregos.com/15416450/backend-developer/'&gt;Ver Oferta de Emprego&lt;/a&gt;]]></description>
            <pubDate>Wed, 13 May 2026 00:00:00 GMT</pubDate>
            <guid>https://www.net-empregos.com/15416450/backend-developer/</guid>
          </item>
          <item>
            <title><![CDATA[Electricista]]></title>
            <dc:creator><![CDATA[Visotela]]></dc:creator>
            <link>https://www.net-empregos.com/15416451/electricista/</link>
            <description><![CDATA[&lt;b&gt;Empresa: &lt;/b&gt;Visotela&lt;br&gt;&lt;b&gt;Categoria: &lt;/b&gt;Indústria / Produção&lt;br&gt;&lt;b&gt;Zona: &lt;/b&gt; Viseu&lt;br&gt;&lt;b&gt;Descrição: &lt;/b&gt;Instala&ccedil;&otilde;es.]]></description>
            <pubDate>Tue, 12 May 2026 00:00:00 GMT</pubDate>
            <guid>https://www.net-empregos.com/15416451/electricista/</guid>
          </item>
          <item>
            <title><![CDATA[Frontend Developer (m/f)]]></title>
            <dc:creator><![CDATA[Globex]]></dc:creator>
            <link>https://www.net-empregos.com/15416452/frontend-developer/</link>
            <description><![CDATA[&lt;b&gt;Empresa: &lt;/b&gt;Globex&lt;br&gt;&lt;b&gt;Categoria: &lt;/b&gt;Informática ( Programação )&lt;br&gt;&lt;b&gt;Zona: &lt;/b&gt; Porto&lt;br&gt;&lt;b&gt;Descrição: &lt;/b&gt;React.]]></description>
            <pubDate>Mon, 11 May 2026 00:00:00 GMT</pubDate>
            <guid>https://www.net-empregos.com/15416452/frontend-developer/</guid>
          </item>
        </channel>
      </rss>
    XML
  end

  before do
    stub_request(:get, "https://www.net-empregos.com/rssfeed.asp")
      .to_return(status: 200, body: rss, headers: { "Content-Type" => "application/rss+xml" })
  end

  it "filters by Categoria field by default and keeps only programming offers" do
    result = described_class.run(category: "Programação")
    expect(result[:found]).to eq(2)
    expect(result[:created]).to eq(2)

    urls = Offer.pluck(:url)
    expect(urls).to include(
      "https://www.net-empregos.com/15416450/backend-developer/",
      "https://www.net-empregos.com/15416452/frontend-developer/",
    )
    expect(urls).not_to include("https://www.net-empregos.com/15416451/electricista/")
  end

  it "parses Zona into location and creator into company on kept entries" do
    described_class.run(category: "Programação")
    dev = Offer.find_by(url: "https://www.net-empregos.com/15416450/backend-developer/")
    expect(dev.company).to eq("Acme Lda")
    expect(dev.location).to eq("Aveiro")
    expect(dev.modality).to eq("remoto")
  end

  it "supports an additional title/description keyword filter" do
    result = described_class.run(category: "Programação", keywords: "react")
    expect(result[:created]).to eq(1)
    expect(Offer.last.title).to match(/Frontend/)
  end

  it "with no category param returns every entry" do
    result = described_class.run
    expect(result[:found]).to eq(3)
  end

  it "raises FetchError on HTTP failure" do
    stub_request(:get, %r{net-empregos\.com}).to_return(status: 503)
    expect { described_class.run }.to raise_error(Scrapers::BaseClient::FetchError, /HTTP 503/)
  end
end
