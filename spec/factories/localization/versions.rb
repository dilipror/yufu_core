FactoryGirl.define do
  factory :localization_version, class: Localization::Version do
    association :localization

    sequence(:name){|n| "version-#{n}"}

    trait :approved do
      state 'approved'
    end
  end
end