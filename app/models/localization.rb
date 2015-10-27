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

  validates :name, presence: true, uniqueness: true, inclusion: AVAILABLE_NAMES, unless: -> {Rails.env.test?}
  validates :language, presence: true, uniqueness: true

  delegate :name, :is_for_profile, to: :language, prefix: true

  after_create do
    I18n.available_locales << self.name.to_sym
  end

  def current?
    name == I18n.locale.to_s
  end

  def get_translations_hash
    trans = {}
    Translation.active_in(self).not_model_localizers.each do |t|
      trans_pointer = trans
      key_array = t.key.to_s.split(".")
      last_key = key_array.delete_at(key_array.length - 1)
      key_array.each do |current|
        begin
          unless trans_pointer.has_key?(current.to_sym)
            trans_pointer[current.to_sym] = {}
          end
          trans_pointer = trans_pointer[current.to_sym]
        rescue => e
          puts "Key: #{t.key} is deprecated. Remove it"
          t.destroy
        end
      end
      begin
        trans_pointer[last_key.to_sym] = t.value
      rescue => e
        puts 'Fail of get all translations'
        puts e.message
        puts e.backtrace.join("\n")
        puts "last key is #{last_key}"
        puts "key is #{t.key}"
        puts "End fail"
      end
    end
    trans
  end

  def self.get_current
    find_by name: I18n.locale.to_s
  end

  def self.default
    find_or_create_by name: 'en'
  end
end
