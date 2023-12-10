# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "Event #{n}"[0, Event::NAME_MAX_LENGTH] }
    description { Faker::Lorem.paragraph }
    date { 2.weeks.from_now.change(hour: 18, min: 30, sec: 0) }
    location { Faker::Address.unique.city }
    association :organizer, factory: :user

    trait :past do
      date { 2.weeks.ago.change(hour: 18, min: 30, sec: 0) }
    end
  end
end
