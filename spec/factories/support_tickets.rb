FactoryGirl.define do
  factory :ticket, :class => 'Support::Ticket' do
    subject "MyString"
    association :theme, factory: :support_theme
    association :user

    trait :delegated do
      state 'delegated_to_expert'
    end
  end
end
