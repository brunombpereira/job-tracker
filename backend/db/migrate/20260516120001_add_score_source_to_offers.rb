class AddScoreSourceToOffers < ActiveRecord::Migration[7.1]
  # Distinguishes a match_score assigned by Scorers::ProfileMatcher
  # ("auto") from one a user typed into the offer form ("manual"), so
  # `rake offers:rescore` can recompute the former without clobbering
  # the latter. Existing rows default to "auto" — almost all offers are
  # scraped, and a stray hand-scored legacy row is acceptable collateral.
  def change
    add_column :offers, :score_source, :string, null: false, default: "auto"
  end
end
