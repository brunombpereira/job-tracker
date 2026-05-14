require "rails_helper"

RSpec.describe Offers::DescriptionFetcher do
  let(:url) { "https://www.net-empregos.com/15356798/backend-developer/" }

  let(:html_with_jsonld) do
    body = {
      "@context" => "https://schema.org/",
      "@type" => "JobPosting",
      "title" => "Backend Developer",
      "description" => "<p>Build and maintain Rails services.</p>",
      "hiringOrganization" => { "name" => "Acme" }
    }.to_json
    "<html><head><script type=\"application/ld+json\">#{body}</script></head></html>"
  end

  describe ".call" do
    it "fetches and saves the description for an offer that has none" do
      offer = Offer.create!(title: "Backend Developer", company: "Acme", url: url, description: nil)
      stub_request(:get, url).to_return(status: 200, body: html_with_jsonld)

      expect(described_class.call(offer)).to be(true)
      expect(offer.reload.description).to include("Build and maintain Rails services")
    end

    it "leaves an offer that already has a description untouched" do
      offer = Offer.create!(title: "X", company: "Y", url: url, description: "already here")

      expect(described_class.call(offer)).to be(false)
      expect(offer.reload.description).to eq("already here")
      expect(WebMock).not_to have_requested(:get, url)
    end

    it "does nothing for an offer with no URL" do
      offer = Offer.create!(title: "X", company: "Y", url: nil, description: nil)
      expect(described_class.call(offer)).to be(false)
    end

    it "returns false (no raise) when the fetch fails" do
      offer = Offer.create!(title: "X", company: "Y", url: url, description: nil)
      stub_request(:get, url).to_return(status: 503)

      expect(described_class.call(offer)).to be(false)
      expect(offer.reload.description).to be_nil
    end

    it "returns false when the page yields no extractable description" do
      offer = Offer.create!(title: "X", company: "Y", url: url, description: nil)
      stub_request(:get, url).to_return(status: 200, body: "<html><body>nothing</body></html>")

      expect(described_class.call(offer)).to be(false)
    end
  end
end
