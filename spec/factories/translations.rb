FactoryGirl.define do
  factory :translation do
    sequence(:key){|n| "key-#{n}"}
    value 'value'
    association :version, factory: :localization_version
  end
end