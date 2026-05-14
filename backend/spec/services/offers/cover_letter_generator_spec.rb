require "rails_helper"

RSpec.describe Offers::CoverLetterGenerator do
  let(:source) { Source.create!(name: "LinkedIn", color: "#0a66c2") }
  let(:offer) do
    Offer.create!(
      title:   "Junior Backend Developer",
      company: "Acme",
      url:     "https://example.com/job/1",
      source:  source,
    )
  end

  before { seed_cover_letter_templates }

  describe ".generate" do
    it "fills the company / position / platform tokens for PT" do
      text = described_class.generate(offer: offer, lang: "pt")
      expect(text).to include("Junior Backend Developer")
      expect(text).to include("Acme")
      expect(text).to include("LinkedIn") # platform = source.name
      expect(text).to include("Aveiro")   # city from Profile.current
    end

    it "fills tokens for EN with English fallback wording" do
      text = described_class.generate(offer: offer, lang: "en")
      expect(text).to include("Dear")
      expect(text).to include("Acme")
      expect(text).to include("Junior Backend Developer")
      expect(text).to include("LinkedIn")
    end

    it "uses a sensible platform fallback when the offer has no source" do
      sourceless = Offer.create!(title: "X", company: "Y", url: "https://ex.com/x")
      pt = described_class.generate(offer: sourceless, lang: "pt")
      en = described_class.generate(offer: sourceless, lang: "en")
      expect(pt).to include("a vossa página de carreiras")
      expect(en).to include("your careers page")
    end

    it "keeps recipient placeholder for the user to fill in" do
      text = described_class.generate(offer: offer, lang: "pt")
      expect(text).to include("[Nome do Recrutador]")
    end

    it "defaults to PT for an unsupported language" do
      text = described_class.generate(offer: offer, lang: "fr")
      expect(text).to include("Caro/a")
    end
  end
end
