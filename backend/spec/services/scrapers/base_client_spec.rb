require "rails_helper"

RSpec.describe Scrapers::BaseClient do
  # Reset the cached regex set after each example since some test cases
  # mutate the env-driven exclusion list.
  after { described_class.reset_excluded_patterns! }

  # A tiny fake client we drive directly to exercise the base-class
  # behavior without depending on a real network/source. Defined via
  # const_set so SOURCE_NAME lands on the class, not the spec file.
  def self.make_client(name, &fetch)
    klass = Class.new(Scrapers::BaseClient)
    klass.const_set(:SOURCE_NAME, name)
    klass.const_set(:SOURCE_COLOR, "#000")
    klass.define_method(:fetch_raw) { |_| fetch.call }
    klass.define_method(:normalize) { |raw| raw.merge(company: "Acme", status: "new") }
    klass
  end

  let(:six_titles_client) do
    self.class.make_client("fake_six") do
      [
        { title: "Junior Ruby Developer",    url: "https://ex.com/1" },
        { title: "Senior Backend Engineer",  url: "https://ex.com/2" },
        { title: "Lead Mobile Developer",    url: "https://ex.com/3" },
        { title: "Sr. Frontend Developer",   url: "https://ex.com/4" },
        { title: "Backend Developer",        url: "https://ex.com/5" },
        { title: "Solutions Architect",      url: "https://ex.com/6" },
      ]
    end
  end

  describe "seniority exclusion" do
    it "skips senior/lead/sr./architect titles by default and keeps junior/mid" do
      result = six_titles_client.run
      expect(result[:found]).to eq(6)
      expect(result[:created]).to eq(2) # Junior Ruby + Backend Developer
      expect(result[:skipped]).to eq(4)

      kept = Offer.joins(:source).where(sources: { name: "Fake Six" }).pluck(:title)
      expect(kept).to contain_exactly("Junior Ruby Developer", "Backend Developer")
    end

    it "respects SCRAPER_EXCLUDE_KEYWORDS env override" do
      ENV["SCRAPER_EXCLUDE_KEYWORDS"] = "senior,lead"   # narrower list
      described_class.reset_excluded_patterns!

      result = six_titles_client.run
      # Senior + Lead excluded; Sr., Architect now kept.
      expect(result[:created]).to eq(4)
    ensure
      ENV.delete("SCRAPER_EXCLUDE_KEYWORDS")
      described_class.reset_excluded_patterns!
    end

    it "word-boundary matches so 'sensor' is not excluded by 'senior'" do
      sensor_client = self.class.make_client("sensor") do
        [{ title: "Sensor Software Developer", url: "https://ex.com/7" }]
      end
      expect { sensor_client.run }.to change(Offer, :count).by(1)
    end
  end

  describe "dedup + missing url" do
    it "skips offers with blank url and already-existing url" do
      Offer.create!(title: "Pre", company: "X", url: "https://ex.com/5")
      result = six_titles_client.run

      # Junior Ruby (#1) goes in; Backend Developer (#5) is dup; the rest
      # are senior-excluded.
      expect(result[:created]).to eq(1)
      expect(result[:skipped]).to eq(5)
    end
  end
end
