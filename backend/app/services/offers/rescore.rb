module Offers
  # Recomputes match_score for auto-scored offers. Match scores are
  # assigned once, at ingest time, from the user's Profile — so editing
  # the profile leaves every existing offer on its stale score until this
  # runs. User-tuned scores (score_source "manual") are left untouched.
  #
  # Usage: Offers::Rescore.call  →  count of offers whose score changed.
  class Rescore
    def self.call(scope: Offer.where(score_source: "auto"))
      new(scope).call
    end

    def initialize(scope)
      @scope = scope
    end

    def call
      Scorers::ProfileMatcher.reset_cache!
      updated = 0

      @scope.find_each do |offer|
        new_score = Scorers::ProfileMatcher.score(offer.attributes.symbolize_keys)
        next if new_score == offer.match_score

        # update_column: no validations, callbacks, or updated_at bump —
        # this is a derived field, not a meaningful edit to the record.
        offer.update_column(:match_score, new_score)
        updated += 1
      end

      updated
    end
  end
end
