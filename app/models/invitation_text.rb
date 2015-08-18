class InvitationText
  include Mongoid::Document

  field :text
  field :name

  belongs_to :user

  has_one :invite

  validates_presence_of :name, :text

  validates :name, uniqueness: {scope: :user_id}



  # before_save :uniq_name
  # validate :uniq_name, if: :check_changed_attributes

  # def uniq_name
  #   errors[:name] << 'already taken' if user.invitation_texts.where(name: name).count > 0
  # end

  # def check_changed_attributes
  #   name.changed?
  # end


end