class Localization::Version
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :version_number, class_name: 'Localization::VersionNumber'
  belongs_to :localization

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
  end

  def self.current(localization)
    approved.where(localization_id: localization.id).desc(:version_number_id)
  end
end