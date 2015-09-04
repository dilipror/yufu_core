class Support::CommentSerializer < ActiveModel::Serializer
  attributes :id, :ticket_id, :text, :created_at, :author_id, :is_public

  has_many :embedded_attachments
end
