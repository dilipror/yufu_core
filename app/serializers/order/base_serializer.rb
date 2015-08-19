class Order::BaseSerializer < ActiveModel::Serializer
  attributes :id, :state, :human_state_name, :type, :cost, :price, :step, :owner_id, :token, :pay_way, :invoice_ids,
             :assignee_id, :number, :ticket_id, :referral_link_id

  def ticket_id
    @object.ticket.try :id
  end

  def invoice_ids
    @object.invoices.distinct(:id)
  end

  def type
    object.class.name.demodulize
  end
end
