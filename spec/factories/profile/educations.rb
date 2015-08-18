# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :education, class: 'Profile::Education' do
    grade "PhD"
    university "MyString"
    is_approved true
  end
end
