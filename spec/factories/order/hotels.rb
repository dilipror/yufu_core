# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :hotel, :class => 'Order::Hotel' do
    greeted_at "2014-11-05 18:23:43"
    info ""
    additional_info "MyString"
  end
end
