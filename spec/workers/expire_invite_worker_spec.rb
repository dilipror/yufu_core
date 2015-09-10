require 'rails_helper'
RSpec.describe ExpireInviteWorker, :type => :worker do

  let(:invite){create :invite}

  describe '#perform' do
    subject{ExpireInviteWorker.new.perform invite}

    it {expect{subject}.to change{invite.expired}.to true}

  end
end