class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Personalized
  include Mongoid::Paperclip
  include Monetizeable
  include Accountable
  include AgentSystem
  extend Enumerize

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  has_mongoid_attached_file :avatar, default_url: "/no-avatar.png", styles: {thumb: '50x50#'}
  validates_attachment_content_type :avatar, content_type: %w(image/jpg image/jpeg image/png)

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""
  field :authentication_token
  field :return_to
  field :back_to_order

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  field :confirmation_token
  field :confirmed_at,         :type => Time
  field :confirmation_sent_at, :type => Time
  field :unconfirmed_email
  field :identification_number
  field :sex
  field :birthday, type: DateTime
  #TODO move contacts information to embedded document and delegate
  field :wechat
  field :skype
  field :qq
  field :additional_email
  field :additional_phone
  field :role_changed_at, type: Time

  field :name_in_pinyin
  field :surname_in_pinyin
  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  field :phone

  # Settings
  field :send_notification_on_email,                     type: Mongoid::Boolean, default: true
  field :send_notification_on_sms,                       type: Mongoid::Boolean, default: true
  field :duplicate_messages_on_additional_email,         type: Mongoid::Boolean, default: false
  field :duplicate_notifications_on_additional_email,    type: Mongoid::Boolean, default: false

  field :role, default: :client
  field :registered_as, default: :client

  enumerize :registered_as, in: [:translator, :client, :agent, :supplier]
  enumerize :role, in: [:translator, :client]

  has_many :managed_profiles, class_name: 'Profile::Translator', inverse_of: :operator, dependent: :nullify

  has_one :profile_client,     class_name: 'Profile::Client',     dependent: :destroy, validate: false
  has_one :profile_translator, class_name: 'Profile::Translator', dependent: :destroy, validate: false

  # billing
  has_one :billing, dependent: :destroy
  has_many :transactions,  class_name: 'Transaction', as: :is_commission_from
  has_many :withdrawals, dependent: :nullify

  # support
  has_many :my_tickets,       class_name: 'Support::Ticket', inverse_of: :user
  has_many :assigned_tickets, class_name: 'Support::Ticket', inverse_of: :assigned_to
  has_many :expert_tickets,   class_name: 'Support::Ticket', inverse_of: :expert
  has_and_belongs_to_many :watched_tickets, class_name: 'Support::Ticket', inverse_of: :watchers

  # From registration
  belongs_to :localization
  # Managed localizations
  has_and_belongs_to_many :localizations
  has_and_belongs_to_many :groups

  embeds_many :permissions
  embeds_many :notifications
  accepts_nested_attributes_for :permissions, :notifications, :profile_translator, :profile_client

  alias :name :email

  scope :without_admins, -> {where _type: 'User'}
  scope :unconfirmed, -> {where confirmed_at: nil}
  default_scope -> {desc :id}

  #check that new  password is not equals to old
  # validate :new_password, if: -> {password.present? && encrypted_password_was.present?}
  validates_format_of :email, :with => /(\A[^-][\w+\-.]*)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,  if: -> {email.present?}
  #validates_uniqueness_of :phone,  if: -> {phone.present?}

  before_save :set_avatar_extension, :after_role_changed, :ensure_authentication_token
  before_create :role_changed_first_time
  after_create :create_default_profiles
  after_create ->(user) {ConfirmationReminderJob.set(wait: 3.days).perform_later(user.id.to_s)}
  # before_save :downcase_email

  delegate :href, to: :referral_link, prefix: true, allow_nil: true

  def authorized_translator?
    role.translator? ? profile_translator.try(:authorized?) : false
  end

  alias :is_authorized_translator :authorized_translator?

  def create_default_profiles
    create_profile_client if profile_client.nil?
    create_profile_translator if profile_translator.nil?
  end

  def can_manage_localizations?
    localizations.count > 0
  end
  alias :can_manage_localizations :can_manage_localizations?


  def can_approve_localization?
    localizations.where(name: 'en').any?
  end
  alias :can_approve_localization :can_approve_localization?

  def need_change_password?
    !self.is_a?(Admin) && self.sign_in_count <= 1
  end

  def can_change_role?
    return true if role_changed_at.nil? || role.translator?
    Time.now - role_changed_at > 24.hours
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def full_name
    first_name.blank? && last_name.blank? ? email : "#{first_name} #{last_name}"
  end

  private
  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end

  def role_changed_first_time
    write_attribute :role_changed_at, nil
  end

  def after_role_changed
    write_attribute :role_changed_at, DateTime.now if role_changed? && persisted? && sign_in_count > 0
  end

  def new_password
    bcrypt   = ::BCrypt::Password.new(encrypted_password_was)
    password = ::BCrypt::Engine.hash_secret("#{self.password}#{self.class.pepper}", bcrypt.salt)
    errors[:password] << I18n.t('mongoid.errors.messages.password_is_not_new') if bcrypt.eql? password
  end

  def set_avatar_extension
    if self.avatar_content_type.nil? || self.avatar_file_name != 'data'
      return true
    end
    begin
      name = SecureRandom.uuid
    end while !User.where(avatar_file_name: name).empty?
    extension = self.avatar_content_type.gsub('image/', '.')
    self.avatar.instance_write(:file_name, name+extension)
  end

  def postpone_email_change?
    false
  end

  def downcase_email
    self.email = self.email.downcase
  end
end
