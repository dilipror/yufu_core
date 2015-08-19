class StatisticSerializer < ActiveModel::Serializer
  attributes :id, :count, :clicked_count, :clicked_percent, :commission, :pass_registration_count,
             :pass_registration_percent, :orders_count, :orders_count_percent
end
