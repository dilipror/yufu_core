class PaymentMethod::BaseSerializer < ActiveModel::Serializer
  attributes :id, :billing_id, :_type, :is_active

  has_one :billing_address

  def billing_id
    @object.billing.to_param
  end
end