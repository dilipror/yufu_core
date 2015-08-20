class Localization::Version
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :version_number, class_name: 'Localization::VersionNumber'
  belongs_to :localization
  has_many :translations, dependent: :destroy

  scope :approved, -> {where state: 'approved'}

  validates_presence_of :version_number, :localization

  state_machine initial: :new do
    state :approved
    state :commited
    state :rejected

    event :commit do
      transition [:new, :rejected] => :commited
    end

    event :reject do
      transition :commited => :rejected
    end

    event :approve do
      transition :commited => :approved
    end

    before_transition on: :approve do |version|
      if version.localization.name == 'en'
        chinese_lang_ids = Language.chinese.distinct :id
        Localization.where(:language_id.in =>  chinese_lang_ids).each do |l|
          Localization::Version.find_or_create_by localization_id: l.id, version_number_id: version.version_number.id
        end
      elsif version.localization.language.is_chinese?
        Localization.where(:language_id.nin => Language.chinese.distinct(:id), :name.ne => 'en').each do |l|
          Localization::Version.find_or_create_by localization_id: l.id, version_number_id: version.version_number.id
        end
      end
      version.translations.model_localizers.each &:localize_model
      true
    end
  end

  def self.current(localization)
    approved.where(localization_id: localization.id).desc(:version_number_id)
  end
end