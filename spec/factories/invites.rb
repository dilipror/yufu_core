FactoryGirl.define do
  factory :invite do
    sequence(:email) {|n| "invite#{n}@example.com"}
  end
end
