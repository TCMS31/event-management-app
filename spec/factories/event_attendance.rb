FactoryBot.define do
  factory :event_attendance do
    association :event
    association :attendee, factory: :user
  end
end
