FactoryGirl.define do
  factory :support_theme, :class => 'Support::Theme' do
    sequence(:name){|n| "theme-#{n}"}
  end
end
