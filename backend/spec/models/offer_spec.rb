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

  describe "#transition_to!" do
    let(:offer) { create(:offer, status: "new") }

    it "allows new → interested" do
      expect { offer.transition_to!("interested") }
        .to change { offer.reload.status }.from("new").to("interested")
    end

    it "records a status_change with reason" do
      offer.transition_to!("interested", reason: "Promising")
      change = offer.status_changes.last
      expect(change.from_status).to eq("new")
      expect(change.to_status).to eq("interested")
      expect(change.reason).to eq("Promising")
    end

    it "raises ArgumentError on invalid transition" do
      expect { offer.transition_to!("interview") }
        .to raise_error(ArgumentError, /cannot transition/)
    end

    it "raises ArgumentError on unknown status" do
      expect { offer.transition_to!("magic") }
        .to raise_error(ArgumentError, /unknown status/)
    end

    it "archives the offer when transitioning to archived" do
      offer.transition_to!("archived")
      offer.reload
      expect(offer.status).to eq("archived")
      expect(offer.archived).to eq(true)
    end

    it "allows new → applied (skip interested)" do
      expect { offer.transition_to!("applied") }
        .to change { offer.reload.status }.to("applied")
    end

    it "allows applied → interview → offer" do
      offer.transition_to!("applied")
      offer.transition_to!("interview")
      expect { offer.transition_to!("offer") }
        .to change { offer.reload.status }.to("offer")
    end

    it "does not allow offer → interview (backward)" do
      offer.transition_to!("applied")
      offer.transition_to!("interview")
      offer.transition_to!("offer")
      expect { offer.transition_to!("interview") }
        .to raise_error(ArgumentError, /cannot transition/)
    end

    it "is atomic — does not save partial state on error" do
      original = offer.status
      begin
        offer.transition_to!("magic")
      rescue ArgumentError
        # expected
      end
      expect(offer.reload.status).to eq(original)
    end
  end
end
