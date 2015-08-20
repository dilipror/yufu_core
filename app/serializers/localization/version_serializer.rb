class Localization::VersionSerializer < ActiveModel::Serializer
  attributes :id, :name, :number, :localization_id, :editable, :state

  def editable
    @object.editable?
  end
end