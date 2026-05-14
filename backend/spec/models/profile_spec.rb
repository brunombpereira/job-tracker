require "rails_helper"

RSpec.describe Profile, type: :model do
  describe ".current" do
    it "creates the single profile row on first use" do
      Profile.delete_all
      expect { Profile.current }.to change(Profile, :count).from(0).to(1)
    end

    it "returns the same row on subsequent calls" do
      Profile.delete_all
      expect(Profile.current).to eq(Profile.current)
    end

    it "ships generic keyword defaults and empty stack tiers" do
      Profile.delete_all
      profile = Profile.current
      expect(profile.positive_title_keywords).to include("junior")
      expect(profile.linkedin_keywords).to eq([ "developer" ])
      expect(profile.primary_keywords).to eq([])
    end
  end

  describe "#matcher_config" do
    it "exposes the keyword lists keyed the way ProfileMatcher expects" do
      profile = Profile.current
      profile.update!(primary_keywords: %w[ruby rails], location_bonus_keywords: %w[remote])

      config = profile.matcher_config
      expect(config["primary"]).to eq(%w[ruby rails])
      expect(config["location_bonus"]).to eq(%w[remote])
      expect(config.keys).to include("secondary", "experimental", "positive_title", "negative_title")
    end
  end
end
