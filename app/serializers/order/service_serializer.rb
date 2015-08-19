class Order::ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :cost, :time, :services_packs_ids, :short_description,#, :order_local_experts_id
             :downpayments, :discount, :support_count, :is_custom,
             :image_url
  def cost
    # @object.cost
    (Currency.exchange @object.cost).to_f
  end

  def downpayments
    (Currency.exchange @object.downpayments).to_f
  end

  def image_url
    @object.image.url
  end

  def services_packs_ids
    @object.services_packs.distinct :id
  end
end
