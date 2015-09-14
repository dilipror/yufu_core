FactoryGirl.define do
  factory :order_commission, :class => 'Order::Commission' do
    key :to_partner
  end

end
