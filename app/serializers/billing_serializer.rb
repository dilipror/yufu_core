class BillingSerializer < ActiveModel::Serializer
  attributes :id, :is_active, :pay_way, :user_id

  has_many :payment_methods

  def user_id
    @object.user.id
  end

end
