FactoryBot.define do
  factory :user do
    sequence(:email) { |n| Faker::Internet.unique.email(name: "user#{n}") }
    password { 'password123' }
  end
end
