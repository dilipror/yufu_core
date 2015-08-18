class CityApproveFilter
  include Filterable

  def self.filter_city(city_id)
    CityApprove.where city_id: city_id
  end

  def self.filter_province(province_id)
    province = Province.find(province_id).name
    CityApprove.where province: province
  end
end