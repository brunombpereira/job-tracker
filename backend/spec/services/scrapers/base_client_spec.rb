require "rails_helper"

RSpec.describe Scrapers::BaseClient do
  # Tiny fake client driven directly to exercise base-class behavior
  # without depending on a real network/source.
  def self.make_client(name, &fetch)
    klass = Class.new(Scrapers::BaseClient)
    klass.const_set(:SOURCE_NAME, name)
    klass.const_set(:SOURCE_COLOR, "#000")
    klass.define_method(:fetch_raw) { |_| fetch.call }
    klass.define_method(:normalize) { |raw| raw.merge(company: "Acme", status: "new") }
    klass
  end

  describe "dedup + url validation" do
    let(:client) do
      self.class.make_client("fake_dedup") do
        [
          { title: "Backend Developer",  url: "https://ex.com/1" },
          { title: "Frontend Developer", url: "https://ex.com/2" },
          { title: "No URL Job",         url: "" }
        ]
      end
    end

    it "creates Offers for valid urls and skips blank ones" do
      result = client.run
      expect(result[:found]).to eq(3)
      expect(result[:created]).to eq(2)
      expect(result[:skipped]).to eq(1)
    end

    it "skips an url that already exists" do
      Offer.create!(title: "Pre", company: "X", url: "https://ex.com/1")
      result = client.run
      expect(result[:created]).to eq(1)
      expect(result[:skipped]).to eq(2)
    end
  end

  describe "auto match_score assignment" do
    it "applies ProfileMatcher when match_score is missing" do
      client = self.class.make_client("fake_score") do
        [ { title: "Junior Ruby Developer", url: "https://ex.com/score", stack: %w[Ruby Rails] } ]
      end
      client.run
      offer = Offer.find_by(url: "https://ex.com/score")
      expect(offer.match_score).to be_between(1, 5)
    end

    it "respects a pre-set match_score from the scraper" do
      client = Class.new(Scrapers::BaseClient).tap do |k|
        k.const_set(:SOURCE_NAME, "fake_preset")
        k.const_set(:SOURCE_COLOR, "#000")
        k.define_method(:fetch_raw) { |_| [ { title: "X", url: "https://ex.com/preset" } ] }
        k.define_method(:normalize) { |raw| raw.merge(company: "Acme", status: "new", match_score: 2) }
      end
      client.run
      expect(Offer.find_by(url: "https://ex.com/preset").match_score).to eq(2)
    end
  end
end
