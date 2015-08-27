class Language
  include Mongoid::Document
  include Mongoid::Paperclip
  include BlankLocalizedFields
  include Filterable

  field :name, localize: true
  field :short_name
  field :is_supported_by_office,       type: Mongoid::Boolean, default: false
  field :office_has_local_translators, type: Mongoid::Boolean, default: false
  field :communication,                type: Mongoid::Boolean, default: false
  field :is_chinese,                   type: Mongoid::Boolean, default: false
  field :support_written_correctors,   type: Mongoid::Boolean, default: false
  field :is_for_profile,               type: Mongoid::Boolean, default: false
  field :is_hieroglyph,                type: Mongoid::Boolean

  belongs_to :senior, class_name: 'Profile::Translator', inverse_of: :assigned_languages
  belongs_to :languages_group

  has_one :localization
  has_and_belongs_to_many :orders_written, :class_name => 'Order::Written'
  # has_one :order_written, :class_name => 'Order::Written', inverse_of: :original_language

  has_mongoid_attached_file :flag, styles: {thumb: '30x30#'}
  validates_attachment_content_type :flag, content_type: /\Aimage\/.*\Z/

  validates_presence_of :name, uniqueness: true
  validates_presence_of :languages_group

  clear_localized :name

  after_save :resolve_senior, if: :senior_id_changed?

  delegate :written_price, :verbal_price,  to: :languages_group, allow_nil: true

  scope :not_chinese, -> {where is_chinese: false}
  scope :chinese,     -> {where is_chinese: true}


  #fitering
  def self.filter_name(name)
    where(name: /.*#{name}.*/i)
  end

  def self.filter_email(email)
    user_ids = User.where(email: /.*#{email}.*/).distinct :id
    translator_ids = Profile::Translator.where(:user_id.in => user_ids).distinct :id
    where :senior_id.in => translator_ids
  end

  def self.filter_group(name)
    group_ids = LanguagesGroup.where(name: /.*#{name}.*/).distinct :id
    where :languages_group_id.in => group_ids
  end


  scope :for_profile, -> (profile) do
    if profile._type == 'Profile::Translator'
      langs_ids = profile.services.map &:language_id
      where :id.in => langs_ids
    else
      raise ArgumentError, 'expect Profile::Translator'
    end

  end

  def self.available_from_chinese
    languages_ids = []
    Profile::Service.each do |service|
      if service.written_approves && /From/.match(service.written_translate_type)
        languages_ids << service.language_id
      end
    end
    languages_ids += Language.where(is_chinese: true).distinct :id
    where(:id.in => languages_ids)
  end

  def self.available_to_chinese
    languages_ids = []
    Profile::Service.each do |service|
      if service.written_approves && /to|To/.match(service.written_translate_type)
        languages_ids << service.language_id
      end
    end
    languages_ids += Language.where(is_chinese: true).distinct :id
    where(:id.in => languages_ids)
  end

  scope :for_communication, -> {where communication: true}
  default_scope -> {order_by :is_chinese.desc, :name.asc}

  def has_senior?
    senior.present?
  end
  alias :has_senior :has_senior?

  def available_levels(city_id = nil)
    translators_ids = CityApprove.where(city_id: city_id).distinct :translator_id
    Profile::Service.approved.where(language_id: id, :translator_id.in => translators_ids).distinct :level
  end

  protected
  def resolve_senior
    fire_old_senior
    if senior.present?
      locale = I18n.locale
      I18n.locale = 'en'

      loc = localization
      if loc.nil?
        iso_codes = ISO_639.find_by_english_name(name)
        true_iso = iso_codes.nil? ? nil : (iso_codes.select {|code| Localization::AVAILABLE_NAMES.include? code}).first
        loc = build_localization(name: true_iso) if true_iso.present?
      end
      if loc.present?
        loc.users << senior.user if loc.present?
        loc.save!
      end
      I18n.locale = locale
    end
  end

  def fire_old_senior
    senior_was = Profile::Translator.where(id: senior_id_was).first
    if senior_was.present? && localization.present?
      localization.users.delete senior_was
    end
  end
end
