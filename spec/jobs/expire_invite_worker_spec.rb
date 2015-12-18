require 'rails_helper'
RSpec.describe ExpireInviteWorker, :type => :worker do

  let(:invite){create :invite, email: 'new@emal.com'}

  describe '#perform' do
    subject{ExpireInviteWorker.new.perform invite.id}

    it {expect{subject}.to change{invite.reload.expired}.to true}

  end
end