class ConfirmationReminderJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user = User.find user_id
    UsersMailer.confirmation_reminder(user).deliver unless user.confirmed?
  end
end
