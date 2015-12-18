require 'rails_helper'
RSpec.describe BanExpireWorker, :type => :worker do

  let(:translator){create :profile_translator, is_banned: true}

  describe '#perform' do
    subject{BanExpireWorker.new.perform translator.id}

    it {expect{subject}.to change{translator.reload.is_banned}.to false}

  end
end