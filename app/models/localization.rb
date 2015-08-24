class Localization
  include Mongoid::Document

  AVAILABLE_NAMES_SYM = [:af, :ar, :az, :bg, :bn, :bs, :ca, :cs, :cy, :da, :de, :el, :en, :eo, :es, :et,
                     :eu, :fa, :fi, :fr, :gl, :he, :hi, :hr, :hu, :id, :is, :it, :ja, :km, :kn, :ko, :lo,
                     :lt, :lv, :mk, :mn, :ms, :nb, :ne, :nl, :nn, :or, :pl, :pt, :rm, :ro, :ru, :sk, :sl,
                     :sr, :sv, :sw, :ta, :th, :tl, :tr, :uk, :ur, :uz, :vi, :wo,
                     'zh-CN', 'zh-HK', 'zh-TW', 'zh-YUE', 'cn-pseudo']

  AVAILABLE_NAMES = Localization::AVAILABLE_NAMES_SYM.map &:to_s

  field :name
  field :enable, type: Mongoid::Boolean, default: false

  belongs_to :language
  has_many :localization_versions, class_name: 'Localization::Version'
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
