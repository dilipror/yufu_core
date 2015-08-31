FactoryGirl.define do
  factory :withdrawal do
    sum 100.0
    association :user
  end
end