FactoryGirl.define do
  factory :invoice_item, :class => 'Invoice::Item' do
    description "MyText"
    cost 200.0
  end
end
