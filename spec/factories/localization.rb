FactoryGirl.define do
  factory :localization do
    sequence(:name) {|n| Localization::AVAILABLE_NAMES[n]}
    association :language
  end
end