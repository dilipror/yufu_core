class CityApproveSerializer < ActiveModel::Serializer
  attributes :id, :is_approved, :with_surcharge, :translator_id

  has_one :city
end
