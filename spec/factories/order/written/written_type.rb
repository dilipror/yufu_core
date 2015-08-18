# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :written_type, :class => 'Order::Written::WrittenType' do
    name 'gan gam style'
    description 'ololol'
    type_name 'document'
    subtypes {[create(:written_subtype)]}
  end
end
