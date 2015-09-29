FactoryGirl.define do
  factory :client_info, :class => 'Order::ClientInfo' do
    last_name 'client'
    first_name 'info'
    wechat 'asdasd'
    sequence(:phone) {|n| "0911#{n}"}
    association :country
  end
end
