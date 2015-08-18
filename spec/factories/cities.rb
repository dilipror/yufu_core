# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :city do
    sequence(:name) {|n| "city-#{n}"}
    association :language
  end
end
