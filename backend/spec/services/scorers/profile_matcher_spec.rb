require "rails_helper"

RSpec.describe Scorers::ProfileMatcher do
  describe ".score" do
    it "rewards multiple primary stack matches" do
      attrs = {
        title:       "Backend Developer",
        description: "Build Rails apps with PostgreSQL and React.",
        stack:       %w[Ruby Rails PostgreSQL],
        location:    nil
      }
      expect(described_class.score(attrs)).to be >= 4
    end

    it "boosts junior-friendly titles" do
      attrs = {
        title:       "Junior Backend Developer",
        description: "Build with Ruby.",
        stack:       [ "Ruby" ],
        location:    nil
      }
      expect(described_class.score(attrs)).to be >= 4
    end

    it "boosts portugal/remote locations" do
      pt_remote = {
        title: "Backend Developer",
        description: "Ruby work.",
        stack: [ "Ruby" ],
        location: "Porto, Portugal",
        modality: "remoto"
      }
      foreign = pt_remote.merge(location: "Mumbai, India", modality: "presencial")
      expect(described_class.score(pt_remote)).to be > described_class.score(foreign)
    end

    it "drops offers with no recognisable stack signal at all" do
      generic = {
        title:       "Construction Worker",
        description: "Bricklayer needed in Aveiro.",
        stack:       [],
        location:    "Aveiro"
      }
      # No primary/secondary/experimental hit → -1; location_bonus +1; net=3-1+1=3
      expect(described_class.score(generic)).to be <= 3
    end

    it "clamps result between 1 and 5" do
      jackpot = {
        title:       "Junior Full-Stack Developer",
        description: "Ruby on Rails, React, TypeScript, PostgreSQL, all day every day.",
        stack:       %w[Ruby Rails React PostgreSQL TypeScript JavaScript Tailwind],
        location:    "Aveiro, Portugal",
        modality:    "remoto"
      }
      expect(described_class.score(jackpot)).to eq(5)
    end

    it "skips mid-level signals as a soft penalty" do
      mid = {
        title:       "Mid-level Backend Developer",
        description: "5+ years of Rails experience.",
        stack:       [ "Ruby", "Rails" ],
        location:    nil
      }
      # 3 + 2 (primary) - 1 (negative title) = 4
      expect(described_class.score(mid)).to eq(4)
    end
  end
end
