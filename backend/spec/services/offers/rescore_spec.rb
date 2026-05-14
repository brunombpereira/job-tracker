require "rails_helper"

RSpec.describe Offers::Rescore do
  # A title with a strong junior + primary-stack signal scores high; a
  # bare title scores neutral. We use that gap to prove a rescore moved
  # the needle without depending on exact ProfileMatcher internals.
  let(:strong_attrs) do
    { title: "Junior Ruby on Rails Developer", company: "Acme", stack: %w[ruby rails] }
  end

  describe ".call" do
    it "recomputes the score for auto-scored offers and returns the change count" do
      offer = Offer.create!(strong_attrs.merge(match_score: 1, score_source: "auto"))

      count = described_class.call
      expect(count).to eq(1)
      expect(offer.reload.match_score).to be > 1
    end

    it "leaves manually-scored offers untouched" do
      offer = Offer.create!(strong_attrs.merge(match_score: 1, score_source: "manual"))

      expect { described_class.call }.not_to(change { offer.reload.match_score })
    end

    it "does not count offers whose score is already correct" do
      correct = Scorers::ProfileMatcher.score(strong_attrs)
      Offer.create!(strong_attrs.merge(match_score: correct, score_source: "auto"))

      expect(described_class.call).to eq(0)
    end

    it "does not bump updated_at" do
      offer = Offer.create!(strong_attrs.merge(match_score: 1, score_source: "auto"))
      expect { described_class.call }.not_to(change { offer.reload.updated_at })
    end
  end
end
