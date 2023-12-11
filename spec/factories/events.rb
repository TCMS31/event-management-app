FactoryBot.define do
  factory :event do
    name { Faker::Lorem.unique.sentence(word_count: 5)[0, 25] }
    description { Faker::Lorem.paragraph }
    date { Faker::Time.forward(days: 30, period: :all) }
    location { Faker::Address.unique.city }
    association :organizer, factory: :user
  end
end
