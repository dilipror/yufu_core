FactoryGirl.define do
  factory :invitation_text do
    sequence(:name) {|n| "name-#{n}"}
    sequence(:text) {|n| "text-#{n}"}
  end
end