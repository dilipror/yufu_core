class Localization::VersionSerializer < ActiveModel::Serializer
  attributes :id, :name, :number, :localization_id, :editable, :state, :independent, :created_at

  def editable
    @object.editable?
  end

  def independent
    @object.independent?
  end
end