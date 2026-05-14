class Profile < ApplicationRecord
  # The personal details + scoring keywords that used to live in the
  # committed config/profile.yml. Single-row table: one self-hosted
  # instance has one profile, edited through the Settings page.

  KEYWORD_FIELDS = %i[
    primary_keywords secondary_keywords experimental_keywords
    positive_title_keywords negative_title_keywords location_bonus_keywords
    linkedin_keywords
  ].freeze

  DETAIL_FIELDS = %i[name city country email phone github linkedin start_date].freeze

  # The one profile row, creating it (with column defaults) on first use.
  # Single-user app, so the first-or-create race is not a concern.
  def self.current
    first || create!
  end

  # Keyword lists keyed the way Scorers::ProfileMatcher expects.
  def matcher_config
    {
      "primary"        => primary_keywords,
      "secondary"      => secondary_keywords,
      "experimental"   => experimental_keywords,
      "positive_title" => positive_title_keywords,
      "negative_title" => negative_title_keywords,
      "location_bonus" => location_bonus_keywords
    }
  end
end
