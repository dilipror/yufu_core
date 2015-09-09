class Localization::Version
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :version_number, class_name: 'Localization::VersionNumber'
  belongs_to :localization
  has_many :translations, dependent: :destroy

  scope :approved, -> {where state: 'approved'}
  scope :not_approved, -> {ne :state =>  'approved'}

  delegate :name, :number, to: :version_number

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
        pseudo_china = Localization.find_or_create_by name: 'cn-pseudo'
        Localization::Version.find_or_create_by localization_id: pseudo_china.id,
                                                version_number_id: version.version_number.id
      elsif version.localization.name == 'cn-pseudo'
        Localization.where(:name.nin => %w(en cn-pseudo zh-CN)).each do |l|
          Localization::Version.find_or_create_by localization_id: l.id, version_number_id: version.version_number.id
        end
      end
      version.translations.model_localizers.each &:localize_model
      # I18nJsExportWorker.perform_async
      # Localization::Version.export
      I18n::JS.export

      true
    end
  end

  def english?
    localization.name == 'en'
  end

  def editable?
    !(%w(commited approved).include? state)
  end

  def self.current(localization)
    approved.where(localization_id: localization.id).desc(:version_number_id)
  end
end