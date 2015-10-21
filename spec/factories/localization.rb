FactoryGirl.define do
  factory :localization do
    sequence(:name) {|n| "locale-#{n}" }
    association :language
  end
end