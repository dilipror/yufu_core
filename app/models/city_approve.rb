class CityApprove
  include Mongoid::Document
  include Approvable
  include Filterable

  field :with_surcharge, type: Mongoid::Boolean, default: false

  field :email
  field :province

  belongs_to :city
  belongs_to :translator, class_name: 'Profile::Translator'

  before_create :set_email, :set_province

  default_scope -> {includes :city}
  scope :with_surcharge,    -> {where with_surcharge: true}
  scope :without_surcharge, -> {where with_surcharge: false}

  #filtering
  def self.filter_city(city_id)
    CityApprove.where city_id: city_id
  end

  def self.filter_province(province_id)
    province = Province.find(province_id).name
    CityApprove.where province: province
  end

  def self.filter_email(email)
    user_ids = User.where(email: /.*#{email}.*/).distinct :id
    translator_ids = Profile::Translator.where(:user_id.in => user_ids).distinct :id
    where :translator_id.in => translator_ids
  end


  def set_email
    self.email = translator.try(:email)
  end

  def set_province
    self.province = city.try(:province).try(:name)
  end

end
