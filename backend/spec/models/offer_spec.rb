require "rails_helper"

RSpec.describe Offer, type: :model do
  describe "validations" do
    subject { build(:offer) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:company) }
    it { is_expected.to validate_uniqueness_of(:url).allow_blank }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
    it do
      is_expected.to validate_numericality_of(:match_score)
        .only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5)
        .allow_nil
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:source).optional }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:status_changes).dependent(:destroy) }
  end

  describe "defaults" do
    it "sets status=new and found_date=today on create" do
      offer = described_class.create!(title: "X", company: "Y")
      expect(offer.status).to eq("new")
      expect(offer.found_date).to eq(Date.current)
      expect(offer.stack).to eq([])
    end
  end

  describe "scopes" do
    let!(:active_offer)   { create(:offer, archived: false) }
    let!(:archived_offer) { create(:offer, archived: true) }

    it ".active excludes archived" do
      expect(described_class.active).to contain_exactly(active_offer)
    end
  end
end
