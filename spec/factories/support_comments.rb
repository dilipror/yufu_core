FactoryGirl.define do
  factory :comment, :class => 'Support::Comment' do
    text "MyString"
    association :author, factory: :user
    association :ticket
  end
end
