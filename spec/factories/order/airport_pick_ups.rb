# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :airport_pick_up, :class => 'Order::AirportPickUp' do
    need_car false
    double_way false
    flight_number "MyString"
    airport "MyString"
    arriving_date "2014-11-05 17:57:46"
  end
end
