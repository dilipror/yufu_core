FactoryGirl.define do
  factory :translation do
    key 'key'
    value 'value'
    association :version, factory: :localization_version
  end
end