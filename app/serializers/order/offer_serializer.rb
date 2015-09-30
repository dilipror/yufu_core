class Order::OfferSerializer < ActiveModel::Serializer
  attributes :id, :assignee, :state

  def assignee
    object.translator.try :id
  end
end
