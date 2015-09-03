class BillingSerializer < ActiveModel::Serializer
  attributes :id, :is_active, :pay_way, :user_id

  has_one :payment_method

  def user_id
    @object.user.id
  end

end
