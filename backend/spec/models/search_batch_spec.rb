require "rails_helper"

RSpec.describe SearchBatch, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "associations" do
    it { is_expected.to have_many(:scraper_runs).dependent(:nullify) }
  end

  describe "#refresh_status!" do
    let(:batch) do
      described_class.create!(status: "pending", sources_requested: %w[adzuna itjobs])
    end

    it "stays running while any child is still pending/running" do
      ScraperRun.create!(source_name: "adzuna", status: "running", search_batch: batch)
      ScraperRun.create!(source_name: "itjobs", status: "succeeded", search_batch: batch,
                         offers_found: 5, offers_created: 4, offers_skipped: 1)

      batch.refresh_status!

      expect(batch.status).to eq("running")
      expect(batch.started_at).to be_within(2.seconds).of(Time.current)
      expect(batch.finished_at).to be_nil
    end

    it "stays running while not all expected children have been created yet" do
      ScraperRun.create!(source_name: "adzuna", status: "succeeded", search_batch: batch)

      batch.refresh_status!

      expect(batch.status).to eq("running")
      expect(batch.finished_at).to be_nil
    end

    it "transitions to succeeded when all children succeed and aggregates counts" do
      ScraperRun.create!(source_name: "adzuna", status: "succeeded", search_batch: batch,
                         offers_found: 10, offers_created: 7, offers_skipped: 3)
      ScraperRun.create!(source_name: "itjobs", status: "succeeded", search_batch: batch,
                         offers_found: 4,  offers_created: 4, offers_skipped: 0)

      batch.refresh_status!

      expect(batch.status).to eq("succeeded")
      expect(batch.offers_found).to eq(14)
      expect(batch.offers_created).to eq(11)
      expect(batch.offers_skipped).to eq(3)
      expect(batch.finished_at).to be_within(2.seconds).of(Time.current)
    end

    it "transitions to failed when every child fails" do
      ScraperRun.create!(source_name: "adzuna", status: "failed", search_batch: batch,
                         error_message: "boom")
      ScraperRun.create!(source_name: "itjobs", status: "failed", search_batch: batch,
                         error_message: "boom")

      batch.refresh_status!

      expect(batch.status).to eq("failed")
      expect(batch.finished_at).to be_within(2.seconds).of(Time.current)
    end

    it "transitions to partial on mixed outcomes" do
      ScraperRun.create!(source_name: "adzuna", status: "succeeded", search_batch: batch,
                         offers_found: 5, offers_created: 3, offers_skipped: 2)
      ScraperRun.create!(source_name: "itjobs", status: "failed", search_batch: batch,
                         error_message: "boom")

      batch.refresh_status!

      expect(batch.status).to eq("partial")
      expect(batch.offers_created).to eq(3)
    end

    it "terminal? is true for succeeded/partial/failed only" do
      %w[succeeded partial failed].each do |s|
        expect(described_class.new(status: s)).to be_terminal
      end
      %w[pending running].each do |s|
        expect(described_class.new(status: s)).not_to be_terminal
      end
    end
  end

  describe "#duration_seconds" do
    it "returns elapsed once finished" do
      batch = described_class.create!(
        status: "succeeded",
        started_at: 5.seconds.ago,
        finished_at: Time.current
      )
      expect(batch.duration_seconds).to be_within(0.5).of(5)
    end

    it "returns nil before finishing" do
      expect(described_class.new.duration_seconds).to be_nil
    end
  end
end
