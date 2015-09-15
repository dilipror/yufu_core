class Order::LocalExpertSerializer < Order::BaseSerializer
  attributes :services_pack_name, :price, :url, :services_pack_id,
             :state, :type, :invoice_ids, :step, :owner_id, :number

  has_many :service_orders



  def url
    Rails.application.routes.url_helpers.edit_order_path(@object)
  end

  def invoice_ids
    @object.invoices.distinct(:id)
  end

  def type
    object.class.name.demodulize
  end
end
