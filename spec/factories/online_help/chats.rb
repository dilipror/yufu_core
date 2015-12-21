FactoryGirl.define do
  factory :chat, class: OnlineHelp::Chat do
    email 'email@example.com'
    association :localization

    trait :inactive do
      is_active false
    end
  end
end
