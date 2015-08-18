FactoryGirl.define do
  factory :localization do
    sequence(:name) {|n| "loc-#{n}"}
    association :language
  end
end