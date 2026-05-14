require "rails_helper"

RSpec.describe Offers::UrlImporter, "source attribution" do
  let(:html_with_jsonld) do
    body = {
      "@context"     => "https://schema.org/",
      "@type"        => "JobPosting",
      "title"        => "Backend Engineer",
      "hiringOrganization" => { "name" => "Acme" },
      "description"  => "Build stuff.",
      "datePosted"   => "2026-05-10"
    }.to_json
    "<html><script type='application/ld+json'>#{body}</script></html>"
  end

  let(:no_metadata_html) do
    %(<html><head><meta property="og:title" content="Random Job"></head></html>)
  end

  it "attributes LinkedIn URLs to a 'LinkedIn' Source with brand color" do
    url = "https://www.linkedin.com/jobs/view/3712345678"
    stub_request(:get, url).to_return(status: 200, body: html_with_jsonld)

    offer = described_class.import(url)
    expect(offer.source.name).to eq("LinkedIn")
    expect(offer.source.color).to eq("#0a66c2")
  end

  it "attributes Indeed (any country subdomain) to a single 'Indeed' Source" do
    pt_url = "https://pt.indeed.com/viewjob?jk=abcd1"
    uk_url = "https://uk.indeed.com/viewjob?jk=abcd2"
    [ pt_url, uk_url ].each { |u| stub_request(:get, u).to_return(status: 200, body: html_with_jsonld.gsub("abcd1", SecureRandom.hex(4))) }

    described_class.import(pt_url)
    described_class.import(uk_url)

    expect(Source.where(name: "Indeed").count).to eq(1)
    expect(Offer.where(source_id: Source.find_by(name: "Indeed").id).count).to eq(2)
  end

  it "attributes Glassdoor URLs to a 'Glassdoor' Source" do
    url = "https://www.glassdoor.com/job-listing/example-JV_IC1234"
    stub_request(:get, url).to_return(status: 200, body: html_with_jsonld)
    expect(described_class.import(url).source.name).to eq("Glassdoor")
  end

  it "falls back to a hostname-derived Source for unknown sites" do
    url = "https://careers.acme-startup.io/jobs/1"
    stub_request(:get, url).to_return(status: 200, body: html_with_jsonld)
    offer = described_class.import(url)
    expect(offer.source.name).to be_present
    expect(offer.source.name).to match(/Careers|Acme/i)
  end
end
