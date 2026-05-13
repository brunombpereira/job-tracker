require "rails_helper"

RSpec.describe Offers::UrlImporter do
  let(:url) { "https://www.linkedin.com/jobs/view/3712345678" }

  let(:jsonld) do
    {
      "@context"     => "https://schema.org/",
      "@type"        => "JobPosting",
      "title"        => "Senior Ruby Engineer",
      "description"  => "<p>Build great Rails apps.</p>",
      "datePosted"   => "2026-05-01",
      "hiringOrganization" => { "@type" => "Organization", "name" => "Acme Co" },
      "jobLocation"  => [
        { "@type" => "Place", "address" => { "addressLocality" => "Lisboa", "addressCountry" => "PT" } }
      ],
      "jobLocationType" => "TELECOMMUTE"
    }
  end

  let(:html_with_jsonld) do
    <<~HTML
      <html><head>
        <script type="application/ld+json">#{jsonld.to_json}</script>
      </head><body>Job listing here.</body></html>
    HTML
  end

  let(:html_no_jsonld) do
    <<~HTML
      <html><head>
        <meta property="og:title" content="Random Job Title">
        <meta property="og:description" content="Brief OG description.">
      </head><body>No JSON-LD.</body></html>
    HTML
  end

  describe ".import" do
    it "creates an Offer from JobPosting JSON-LD with correct mapping" do
      stub_request(:get, url).to_return(status: 200, body: html_with_jsonld)

      offer = nil
      expect { offer = described_class.import(url) }.to change(Offer, :count).by(1)
      expect(offer.title).to eq("Senior Ruby Engineer")
      expect(offer.company).to eq("Acme Co")
      expect(offer.location).to eq("Lisboa, PT")
      expect(offer.modality).to eq("remoto")
      expect(offer.description).to include("Build great Rails apps")
      expect(offer.posted_date).to eq(Date.new(2026, 5, 1))
      expect(offer.url).to eq(url)
    end

    it "marks non-remote postings as presencial" do
      onsite = jsonld.merge("jobLocationType" => "ONSITE")
      onsite_html = "<html><script type=\"application/ld+json\">#{onsite.to_json}</script></html>"
      stub_request(:get, url).to_return(status: 200, body: onsite_html)

      offer = described_class.import(url)
      expect(offer.modality).to eq("presencial")
    end

    it "falls back to OpenGraph when no JobPosting JSON-LD is present" do
      stub_request(:get, url).to_return(status: 200, body: html_no_jsonld)
      offer = described_class.import(url)
      expect(offer.title).to eq("Random Job Title")
      expect(offer.company).to eq("linkedin.com")
      expect(offer.description).to eq("Brief OG description.")
    end

    it "rejects an already-imported URL with a friendly message" do
      Offer.create!(title: "Pre", company: "Acme", url: url)
      expect { described_class.import(url) }
        .to raise_error(described_class::ImportError, /Já existe/)
    end

    it "rejects blank/invalid URLs" do
      expect { described_class.import("") }
        .to raise_error(described_class::ImportError, /URL em branco/)
      expect { described_class.import("ftp://nope") }
        .to raise_error(described_class::ImportError, /URL inválido/)
    end

    it "raises ImportError with HTTP status on non-2xx" do
      stub_request(:get, url).to_return(status: 403)
      expect { described_class.import(url) }
        .to raise_error(described_class::ImportError, /HTTP 403/)
    end

    it "raises ImportError when no JSON-LD and no OG title found" do
      stub_request(:get, url).to_return(status: 200, body: "<html><body>nothing</body></html>")
      expect { described_class.import(url) }
        .to raise_error(described_class::ImportError, /Não encontrei/)
    end
  end
end
