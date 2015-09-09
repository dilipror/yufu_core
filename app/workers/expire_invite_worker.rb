class ExpireInviteWorker
  include Sidekiq::Worker

  def perform(invite_id)
    invite = Invite.find invite_id
    invite.update expired: true
  end
end