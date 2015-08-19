class Invoice::ItemSerializer < ActiveModel::Serializer
  attributes :id, :description, :cost, :number

  def cost
    @object.exchanged_cost
  end
end
