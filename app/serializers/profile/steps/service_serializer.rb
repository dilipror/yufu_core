class Profile::Steps::ServiceSerializer < Profile::Steps::BaseSerializer
  attributes :id, :hsk_level, :cities, :cities_with_surcharge, :directions, :chinese_description

  has_many :services

  def is_full
    @object.is_updated && @object.valid?
  end


  def cities
    @object.city_ids.map  &:to_s
  end

  def cities_with_surcharge
    @object.cities_with_surcharge_ids.map &:to_s
  end

  def directions
    @object.direction_ids.map &:to_s
  end
end