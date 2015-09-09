class Notification
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  attr_accessor :mailer, :sms_mailer

  field :message

  embedded_in :user
  belongs_to :object, polymorphic: true

  default_scope -> {desc :created_at}
  index({created_at: 1}, {expire_after_seconds: 1.month})

  after_create do
    mail = self.mailer.is_a?(Proc) ? mailer.call(self.user, self.object) : (self.mailer || UsersMailer.new_notification(self))
    mail.deliver if user.send_notification_on_email? || user.duplicate_notifications_on_additional_email?

    if self.sms_mailer.is_a?(Proc) && user.send_notification_on_sms?
      sms_mailer.call(self.user, self.object).deliver
    end
  end

  def message
    I18n.t(super)
  end
end
