FactoryGirl.define do
  factory :order_base, class: Order::Base do
    state :new
    association :owner, factory: :profile_client
  end

  factory :order_verbal, class: Order::Verbal do

    include_near_city true
    association :owner,                      factory: :profile_client
    association :location,                   factory: :city
    association :translator_native_language, factory: :language
    association :native_language,            factory: :language
    association :language,                   factory: :language
    level       'guide'
    association :main_language_criterion,    factory: :order_language_criterion

    reservation_dates   {[build(:order_reservation_date)]}


    transient do
      reserve_language_criterions_count 5
    end

    after(:create) do |order, evaluator|
      create_list(:order_language_criterion, evaluator.reserve_language_criterions_count,
                  reserve_socket: order) if order.reserve_language_criterions.blank?
    end
  end

  factory :wait_offers_order, parent: :order_verbal do
    state 'wait_offer'
  end

  factory :order_written, class: Order::Written do
    association :owner, factory: :profile_client
    translation_type 'translate'
    level 'document'
    association :original_language, factory: :language
    association :translation_language, factory: :language
    quantity_for_translate 23
    order_type {create(:written_type)}
  end

  factory :order_local_expert, class: Order::LocalExpert do
    association :owner, factory: :profile_client
    service_orders {[build(:local_expert_service_order)]}
    services_pack {create(:service_pack)}
  end
end