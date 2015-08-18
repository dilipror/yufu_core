# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :permission do
    name "MyString"
    subject_class "MyString"
    action "MyString"
    description "MyText"
  end
end
