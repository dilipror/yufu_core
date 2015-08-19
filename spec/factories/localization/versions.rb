FactoryGirl.define do
  factory :localization_version do
    association :version_number
    association :localization
  end
end