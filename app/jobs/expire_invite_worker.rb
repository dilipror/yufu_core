class ExpireInviteWorker < ActiveJob::Base
  queue_as :default

  def perform(invite_id)
    invite = Invite.find invite_id
    invite.update! expired: true
  end
end