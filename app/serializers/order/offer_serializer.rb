class Order::OfferSerializer < ActiveModel::Serializer
  attributes :id, :status, :is_confirmed, :assignee

  def assignee
    object.translator.try :id
  end
end
