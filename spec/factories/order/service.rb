# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :local_expert_service, :class => 'Order::Service' do
    name 'gan gam style'
    cost 100500
    time 'last year'
    # services_pack {[build(:service_pack)]}
  end
end
