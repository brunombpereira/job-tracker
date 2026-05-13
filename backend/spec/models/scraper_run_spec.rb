require "rails_helper"

RSpec.describe ScraperRun, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:source_name) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "lifecycle helpers" do
    let(:run) { described_class.create!(source_name: "adzuna", status: "pending") }

    it "#mark_running! transitions to running with started_at" do
      expect { run.mark_running! }
        .to change { run.status }.from("pending").to("running")
      expect(run.started_at).to be_within(2.seconds).of(Time.current)
    end

    it "#mark_succeeded! records counts + finished_at" do
      run.mark_running!
      run.mark_succeeded!(found: 10, created: 7, skipped: 3)

      expect(run.status).to eq("succeeded")
      expect(run.offers_found).to eq(10)
      expect(run.offers_created).to eq(7)
      expect(run.offers_skipped).to eq(3)
      expect(run.finished_at).to be_within(2.seconds).of(Time.current)
    end

    it "#mark_failed! stores the message truncated" do
      run.mark_failed!("boom" * 500)
      expect(run.status).to eq("failed")
      expect(run.error_message.length).to be <= 1000
    end

    it "#duration_seconds returns nil before finishing" do
      expect(run.duration_seconds).to be_nil
    end

    it "#duration_seconds returns elapsed once finished" do
      run.update!(started_at: 5.seconds.ago, finished_at: Time.current)
      expect(run.duration_seconds).to be_within(0.5).of(5)
    end
  end
end
