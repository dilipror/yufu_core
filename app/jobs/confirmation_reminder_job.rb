class ConfirmationReminderJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user = User.find user_id
    UsersMailer.confirmation_reminder_23(user).deliver unless user.confirmed?
  end
end
