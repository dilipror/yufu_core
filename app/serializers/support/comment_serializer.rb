class Support::CommentSerializer < ActiveModel::Serializer
  attributes :id, :ticket_id, :text, :created_at, :author_id

  has_many :embedded_attachments
end
