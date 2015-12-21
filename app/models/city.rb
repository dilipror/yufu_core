class City
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, localize: true
  field :position, type: Integer

  belongs_to :language
  belongs_to :province
  # belongs_to :senior, class_name: 'Profile::Translator'

  has_many :city_approves, class_name: 'CityApprove'
  has_one :office

  default_scope -> {asc :name}

  scope :with_approved_translators, -> {
    cities_ids = []
    Profile::Translator.approved.each do |pr|
      cities_ids += pr.city_approves.approved.distinct(:city_id)
    end
    City.where :id.in => cities_ids
  }
  scope :available_for,  -> (translator) {
    ids = translator.city_approves.approved.distinct :city_id
    City.where :id.in => ids
  }

  scope :supported, -> {
    city_ids = CityApprove.approved.distinct :city_id
    City.where :id.in => city_ids
  }

  scope :available_for_order, -> {
    translator_ids = Profile::Service.where(is_approved: true).distinct :translator_id
    city_ids = []
    translator_ids.each do |translator_id|
      city_ids += Profile::Translator.find(translator_id).city_approves.distinct(:city_id)
    end
    City.where :id.in => city_ids
  }
  def supported?
    language_ids(false).length > 0
  end
  alias :is_supported :supported?

  def supported_with_surcharge?
    language_ids(true).length > 0
  end
  alias :is_supported_with_surcharge :supported_with_surcharge?

  def language_ids(include_near_city)
    if include_near_city
      translator_ids = city_approves.approved.distinct :translator_id
    else
      translator_ids = city_approves.without_surcharge.approved.distinct :translator_id
    end

    Profile::Service.approved.where(:translator_id.in => translator_ids, only_written: false).distinct :language_id
  end
end
