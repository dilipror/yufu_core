class Localization::Version
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  # DEPRECATED
  belongs_to :version_number, class_name: 'Localization::VersionNumber'

  belongs_to :parent_version, class_name: 'Localization::Version'
  belongs_to :localization
  has_many :translations, dependent: :destroy

  scope :approved, -> {where state: 'approved'}
  scope :not_approved, -> {ne :state =>  'approved'}
  scope :dependent, -> {ne parent_version_id: nil}
  scope :english, -> {where localization_id: Localization.default.id}

  validates_presence_of :name, :localization
  
  after_save :export, if: -> {state_changed? && state == 'approved'}

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
                                                name: version.name,
                                                parent_version: version
      elsif version.localization.name == 'cn-pseudo'
        Localization.where(:name.nin => %w(en cn-pseudo zh-CN)).each do |l|
          Localization::Version.find_or_create_by localization_id: l.id, name: version.name,
                                                  parent_version: version.parent_version
        end
      end
      version.translations.model_localizers.each &:localize_model
      true
    end
  end

  def number
    id.to_s[0..7]
  end

  def english?
    localization.name == 'en'
  end

  def independent?
    parent_version.nil?
  end

  def editable?
    !(%w(commited approved).include? state)
  end

  def self.current(localization)
    approved.where(localization_id: localization.id).desc(:version_number_id)
  end

  def export
    I18n::JS.export unless Rails.env.test?
  end

end