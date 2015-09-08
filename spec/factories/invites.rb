FactoryGirl.define do
  factory :invite do
    sequence(:email) {|n| "invite#{n}@example.com"}
    association :overlord, factory: :user
  end
end
