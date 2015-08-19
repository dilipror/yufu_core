class PartnersClientSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :middle_name, :orders_count

  def orders_count
    object.orders.count
  end

end
