class Localization::Version
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :name
  field :state_before_delete

  belongs_to :parent_version, class_name: 'Localization::Version'
  belongs_to :localization
  has_many :translations, dependent: :destroy

  scope :approved, -> {where state: 'approved'}
  scope :not_approved, -> {ne :state =>  'approved'}
  scope :opened, -> {where state: 'new'}
  scope :commited, -> {where state: 'commited'}
  scope :dependent, -> {ne parent_version_id: nil}
  scope :english, -> {where localization_id: Localization.default.id}

  default_scope -> {desc :id}

  validates_presence_of :name, :localization

  state_machine initial: :new do
    state :approved
    state :commited
    state :rejected
    state :deleted

    event :delete_version do
      transition any => :deleted
    end

    event :restore_version do
      transition :deleted => any
    end

    event :commit do
      transition [:new, :rejected] => :commited
    end

    event :revert_commit do
      transition :commited => :new
    end

    event :reject do
      transition :commited => :rejected
    end

    event :approve do
      transition :commited => :approved
    end

    before_transition on: :delete_version do |version|
      version.state_before_delete = version.state
      version.destroy
    end

    before_transition on: :restore_version do |version|
      version.restore recursive: true
    end

    after_transition on: :restore_version do |version|
      version.update_attribute :state, version.state_before_delete || :new
      version.update_attribute :state_before_delete, nil
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
    !(%w(commited approved deleted).include? state)
  end

  def self.current(localization)
    approved.where(localization_id: localization.id).desc(:version_number_id)
  end
end