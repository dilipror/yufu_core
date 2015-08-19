class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :message, :object_type, :object_id, :created_at
end
