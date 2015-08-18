# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "user#{n}@example.com"}
    confirmed_at Date.yesterday
    password 'password'
  end

  factory :admin, class: Admin do
    sequence(:email) {|n| "admin#{n}@example.com"}
    confirmed_at Date.yesterday
    password 'password'
  end

  factory :translator, class: User do
    sequence(:email) {|n| "translator#{100 + n}@example.com"}
    password 'password'
    confirmed_at Date.yesterday
    role 'translator'
  end


  factory :client, class: User do
    sequence(:email) {|n| "user#{300 + n}@example.com"}
    password 'password'
    confirmed_at Date.yesterday
    role 'client'
  end
end
