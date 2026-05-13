FactoryBot.define do
  factory :source do
    sequence(:name) { |n| "Source ##{n}" }
    color { "#4a90b8" }
  end
end
