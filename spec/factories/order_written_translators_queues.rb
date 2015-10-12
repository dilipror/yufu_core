FactoryGirl.define do
  factory :order_written_translators_queue, :class => 'Order::Written::TranslatorsQueue' do
    lock_to "2015-08-17"
    association :order_written, factory: :wait_assignee_order
  end
end
