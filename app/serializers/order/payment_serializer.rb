class Order::PaymentSerializer < ActiveModel::Serializer
  attributes :id, :sum, :state, :user_id, :pay_way_id, :created_at, :partial_sum

  def user_id
    @object.invoice.try(:subject).try(:owner).try(:user).try :id
  end
end
