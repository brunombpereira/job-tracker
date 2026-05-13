FactoryBot.define do
  factory :offer do
    title       { "Junior Web Developer" }
    company     { Faker::Company.name }
    location    { "Porto, Portugal" }
    modality    { %w[presencial hibrido remoto].sample }
    stack       { %w[Ruby Rails JavaScript React PostgreSQL].sample(3) }
    url         { Faker::Internet.unique.url }
    match_score { rand(1..5) }
    status      { "new" }
    found_date  { Date.current }
    source

    trait :applied do
      status { "applied" }
      applied_date { Date.current - 2.days }
    end

    trait :high_match do
      match_score { 5 }
      stack { %w[Ruby Rails React PostgreSQL] }
    end
  end
end
