# The match scorer and cover-letter generator read from Profile.current
# (which replaced the old config/profile.yml). Seed a realistic profile
# before every example so specs that depend on scoring or cover-letter
# tokens have stable keyword lists and personal fields to work with.
#
# Specs that need a different profile state can re-update Profile.current
# in their own before block.
RSpec.configure do |config|
  config.before do
    Profile.current.update!(
      name:       "Test User",
      city:       "Aveiro",
      country:    "Portugal",
      email:      "test@example.com",
      start_date: "imediato",
      primary_keywords:        %w[ruby rails react postgresql javascript typescript],
      secondary_keywords:      %w[sql html css tailwind rspec git api],
      experimental_keywords:   %w[python flask],
      positive_title_keywords: %w[junior jr entry graduate trainee intern],
      negative_title_keywords: [ "mid-level", "5+ years", "7+ years" ],
      location_bonus_keywords: %w[portugal aveiro porto lisboa remote remoto hybrid hibrido],
      linkedin_keywords:       %w[developer]
    )
    Scorers::ProfileMatcher.reset_cache!
  end
end
