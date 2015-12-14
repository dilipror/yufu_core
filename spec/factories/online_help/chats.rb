FactoryGirl.define do
  factory :chat, class: OnlineHelp::Chat do
    email 'email@example.com'
    association :localization

    trait :in_active do
      is_active false
    end
  end
end
