class Order::ServiceOrderSerializer < ActiveModel::Serializer
  attributes :id, :cost, :service_id, :count, :name, :support_custom, :description

  def name
    @object.service.name
  end
  # def cost
  #   @object.cost
  #   # 100
  # end

  # def order_local_experts_id
  #   Order::LocalExpert.last.id
  # end
end
