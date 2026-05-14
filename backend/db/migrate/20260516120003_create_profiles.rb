class CreateProfiles < ActiveRecord::Migration[7.1]
  # The profile that drives match scoring, cover-letter generation, and
  # the LinkedIn search keywords. Single-row table (one self-hosted
  # instance = one profile) — see Profile.current. Replaces the old
  # committed config/profile.yml so personalization happens in the app,
  # not by editing a file in the repo.
  def change
    create_table :profiles do |t|
      # Personal details — cover-letter tokens. Nullable: a fresh install
      # has none until the user fills in the Settings page.
      t.string :name
      t.string :city
      t.string :country
      t.string :email
      t.string :phone
      t.string :github
      t.string :linkedin
      t.string :start_date # free text, e.g. "immediately" / "1 month notice"

      # Match-scoring keyword lists. Stack tiers are inherently personal —
      # they ship empty. The title/location signal lists ship with sane
      # generic defaults so scoring is reasonable before customization.
      t.string :primary_keywords,        array: true, null: false, default: []
      t.string :secondary_keywords,      array: true, null: false, default: []
      t.string :experimental_keywords,   array: true, null: false, default: []
      t.string :positive_title_keywords, array: true, null: false,
                                         default: %w[junior jr entry graduate trainee intern internship]
      t.string :negative_title_keywords, array: true, null: false,
                                         default: [ "mid-level", "5+ years", "7+ years", "8+ years", "10+ years" ]
      t.string :location_bonus_keywords, array: true, null: false,
                                         default: %w[remote remoto hybrid hibrido]

      # Keywords the LinkedIn scraper searches with — one query per entry.
      t.string :linkedin_keywords, array: true, null: false, default: [ "developer" ]

      t.timestamps
    end
  end
end
