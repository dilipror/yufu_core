FactoryGirl.define do
  factory :ticket, :class => 'Support::Ticket' do
    subject "MyString"
    association :theme, factory: :support_theme
    association :user
  end
end
