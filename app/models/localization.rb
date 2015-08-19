class Localization
  include Mongoid::Document

  AVAILABLE_NAMES = (Rails.application.config.i18n.available_locales.map &:to_s)


  field :name
  field :enable, type: Mongoid::Boolean, default: false

  belongs_to :language
  has_and_belongs_to_many :users

  scope :enabled, -> {where enable: true}

  validates :name, presence: true, uniqueness: true, inclusion: AVAILABLE_NAMES
  validates :language, presence: true, uniqueness: true

  delegate :name, :is_for_profile, to: :language, prefix: true

  def current?
    name == I18n.locale.to_s
  end

  def self.get_current
    find_by name: I18n.locale.to_s
  end

  def self.default
    find_or_create_by name: 'en'
  end
end
