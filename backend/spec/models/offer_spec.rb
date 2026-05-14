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

    describe ".needs_followup" do
      it "includes applied offers past the follow-up window" do
        stale = create(:offer, status: "applied",
                               applied_date: (described_class::FOLLOWUP_DAYS + 1).days.ago)
        expect(described_class.needs_followup).to include(stale)
      end

      it "excludes applied offers still inside the window" do
        fresh = create(:offer, status: "applied", applied_date: Date.current)
        expect(described_class.needs_followup).not_to include(fresh)
      end

      it "excludes offers that have moved past 'applied'" do
        moved = create(:offer, status: "interview",
                               applied_date: 30.days.ago)
        expect(described_class.needs_followup).not_to include(moved)
      end

      it "excludes archived offers" do
        archived = create(:offer, status: "applied", archived: true,
                                  applied_date: 30.days.ago)
        expect(described_class.needs_followup).not_to include(archived)
      end
    end
  end

  describe "applied_date stamping" do
    it "stamps applied_date when an offer enters 'applied' via transition_to!" do
      offer = create(:offer, status: "new")
      expect { offer.transition_to!("applied") }
        .to change { offer.reload.applied_date }.from(nil).to(Date.current)
    end

    it "stamps applied_date when status is set to 'applied' directly" do
      offer = create(:offer, status: "new")
      offer.update!(status: "applied")
      expect(offer.reload.applied_date).to eq(Date.current)
    end

    it "does not overwrite an applied_date that is already set" do
      earlier = 10.days.ago.to_date
      offer = create(:offer, status: "applied", applied_date: earlier)
      offer.transition_to!("interview")
      expect(offer.reload.applied_date).to eq(earlier)
    end
  end

  describe "#needs_followup" do
    it "is true for a stale applied offer" do
      offer = build(:offer, status: "applied",
                            applied_date: (described_class::FOLLOWUP_DAYS + 1).days.ago)
      expect(offer.needs_followup).to be(true)
    end

    it "is false for a recently applied offer" do
      offer = build(:offer, status: "applied", applied_date: Date.current)
      expect(offer.needs_followup).to be(false)
    end

    it "is exposed in the JSON representation" do
      offer = build(:offer, status: "applied", applied_date: Date.current)
      expect(offer.as_json).to have_key("needs_followup")
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
