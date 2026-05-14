require "rails_helper"

RSpec.describe Scrapers::Health do
  # Build a ScraperRun for `source` with deterministic ordering — `age`
  # is how many minutes ago the run was created (smaller = more recent).
  def run(source, status:, found: 0, age: 0)
    ScraperRun.create!(
      source_name: source,
      status: status,
      offers_found: found,
      created_at: age.minutes.ago,
      finished_at: age.minutes.ago
    )
  end

  def entry(report, key)
    report.find { |e| e.key == key }
  end

  describe ".report" do
    it "returns one entry per registered source, in registry order" do
      report = described_class.report

      expect(report.map(&:key)).to eq(Scrapers::Registry.available)
    end

    it "marks a source with no run history as unknown" do
      expect(entry(described_class.report, "remotive").status).to eq(:unknown)
    end

    it "marks a source whose recent runs all succeeded with finds as ok" do
      run("remotive", status: "succeeded", found: 12, age: 2)
      run("remotive", status: "succeeded", found: 8,  age: 1)

      e = entry(described_class.report, "remotive")
      expect(e.status).to eq(:ok)
      expect(e.last_found).to eq(8)
      expect(e.last_status).to eq("succeeded")
    end

    it "marks a source with a single recent failure as degraded" do
      run("linkedin", status: "succeeded", found: 5, age: 2)
      run("linkedin", status: "failed",        age: 1)

      e = entry(described_class.report, "linkedin")
      expect(e.status).to eq(:degraded)
      expect(e.consecutive_failures).to eq(1)
    end

    it "marks a source with two+ consecutive failures as down" do
      run("linkedin", status: "succeeded", found: 5, age: 3)
      run("linkedin", status: "failed",        age: 2)
      run("linkedin", status: "failed",        age: 1)

      e = entry(described_class.report, "linkedin")
      expect(e.status).to eq(:down)
      expect(e.consecutive_failures).to eq(2)
    end

    it "treats a succeeded-but-found-nothing run as a zero find, not a failure" do
      run("net_empregos", status: "succeeded", found: 0, age: 1)

      e = entry(described_class.report, "net_empregos")
      expect(e.status).to eq(:degraded)
      expect(e.consecutive_zero_finds).to eq(1)
      expect(e.consecutive_failures).to eq(0)
    end

    it "marks a source with three+ consecutive zero finds as down" do
      3.times { |i| run("net_empregos", status: "succeeded", found: 0, age: i + 1) }

      expect(entry(described_class.report, "net_empregos").status).to eq(:down)
    end

    it "resets the consecutive count at the first run that breaks the streak" do
      run("teamlyzer", status: "failed",                age: 3)
      run("teamlyzer", status: "succeeded", found: 7,   age: 2)
      run("teamlyzer", status: "failed",                age: 1)

      e = entry(described_class.report, "teamlyzer")
      expect(e.consecutive_failures).to eq(1)
      expect(e.status).to eq(:degraded)
    end

    it "ignores runs for sources no longer in the registry" do
      run("adzuna", status: "failed", age: 1) # retired source

      expect(described_class.report.map(&:key)).not_to include("adzuna")
    end
  end
end
