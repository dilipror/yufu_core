FactoryGirl.define do
  factory :localization_version, class: Localization::Version do
    association :version_number, factory: :localization_version_number
    association :localization

    trait :approved do
      state 'approved'
    end
  end
end