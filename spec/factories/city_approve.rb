# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :city_approve do
    association :city
    is_approved true
  end
end
