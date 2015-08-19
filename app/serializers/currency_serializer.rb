class CurrencySerializer < ActiveModel::Serializer
  attributes :id, :name, :iso_code, :symbol

  def id
    @object.iso_code
  end
end
