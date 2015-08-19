class CitySerializer < ActiveModel::Serializer
  attributes :id, :name, :province_id, :is_supported, :is_supported_with_surcharge, :language_ids
end
