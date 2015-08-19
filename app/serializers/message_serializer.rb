class MessageSerializer < ActiveModel::Serializer
  attributes :id, :body, :recipient_id, :sender_id, :from_backoffice

  has_many :attachments

  def sender_id
    @object.sender_id.to_s
  end

  def recipient_id
    @object.recipient_id.to_s
  end
end
