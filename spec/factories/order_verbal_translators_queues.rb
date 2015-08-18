FactoryGirl.define do
  factory :order_verbal_translators_queue, :class => 'Order::Verbal::TranslatorsQueue' do
    lock_to "2015-08-17"
    association :order_verbal, factory: :wait_offers_order
  end
end
