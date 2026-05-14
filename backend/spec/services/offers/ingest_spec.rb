require "rails_helper"

RSpec.describe Offers::Ingest do
  let(:source) { Source.create!(name: "Remotive", color: "#3da5d9") }
  let(:base_attrs) do
    { title: "Junior Rails Developer", company: "Acme", url: "https://ex.com/job/1" }
  end

  describe ".call" do
    it "creates an offer and reports :created" do
      result = nil
      expect { result = described_class.call(base_attrs, source: source) }
        .to change(Offer, :count).by(1)

      expect(result).to be_created
      expect(result.offer.title).to eq("Junior Rails Developer")
      expect(result.offer.source_id).to eq(source.id)
    end

    it "skips a duplicate URL without creating a row" do
      Offer.create!(base_attrs)

      result = nil
      expect { result = described_class.call(base_attrs) }
        .not_to change(Offer, :count)
      expect(result.outcome).to eq(:skipped_duplicate)
      expect(result).to be_skipped
    end

    it "allows a blank-URL offer by default" do
      result = described_class.call(base_attrs.except(:url))
      expect(result).to be_created
      expect(result.offer.url).to be_nil
    end

    it "skips a blank-URL offer when skip_blank_url is set" do
      result = nil
      expect { result = described_class.call(base_attrs.except(:url), skip_blank_url: true) }
        .not_to change(Offer, :count)
      expect(result.outcome).to eq(:skipped_blank_url)
    end

    it "reports :invalid with messages for an unsaveable row" do
      result = nil
      expect { result = described_class.call(base_attrs.merge(company: "")) }
        .not_to change(Offer, :count)
      expect(result.outcome).to eq(:invalid)
      expect(result.errors).to be_present
    end

    it "assigns an auto match_score when none is given" do
      result = described_class.call(base_attrs.merge(stack: %w[ruby rails react]))
      expect(result.offer.match_score).to be_between(1, 5)
      expect(result.offer.score_source).to eq("auto")
    end

    it "keeps a provided match_score and does not tag it auto" do
      result = described_class.call(base_attrs.merge(match_score: 2))
      expect(result.offer.match_score).to eq(2)
      expect(result.offer.score_source).to eq("auto") # column default, untouched
    end

    it "does not score when score: false" do
      result = described_class.call(base_attrs, score: false)
      expect(result.offer.match_score).to be_nil
    end

    it "treats a URL unique-index race as a duplicate" do
      # Simulate a concurrent insert: the dedup check and validation pass,
      # but the DB unique index rejects the row at save time.
      offer = Offer.new(base_attrs)
      allow(Offer).to receive(:new).and_return(offer)
      allow(offer).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      result = described_class.call(base_attrs)
      expect(result.outcome).to eq(:skipped_duplicate)
    end
  end
end
