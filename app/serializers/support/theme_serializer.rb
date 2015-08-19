class Support::ThemeSerializer < ActiveModel::Serializer
  attributes :id, :name, :number, :for_local_expert
end
