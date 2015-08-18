# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :written_subtype, :class => 'Order::Written::WrittenSubtype' do
    name 'subtype'
    description 'zazazaz'
  end
end
