# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :direction do
    sequence(:name) {|n| "lan-#{n}"}
  end
end
