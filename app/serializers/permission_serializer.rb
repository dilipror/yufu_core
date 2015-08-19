class PermissionSerializer < ActiveModel::Serializer
  attributes :id, :action, :subject_class
end