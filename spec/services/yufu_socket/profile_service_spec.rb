require 'rails_helper'
require 'byebug'

RSpec.describe YufuSocket::ProfileService do

  let(:profile){create :user}
  let(:service){YufuSocket::ProfileService.new(profile)}
  let(:redis_instance){ MockRedis.new}
  #let(:subscriber){Thread.new { YufuSocket::RedisSubscriberService.new([],"websockets").process}}

  describe '#profile_created!' do

    subject{service.profile_created!}

    before(:each) do
      allow(redis_instance).to receive(:publish)
      allow(service).to receive(:connection).and_return(redis_instance)
    end

    context 'profile is valid' do
      before(:each){allow(profile).to receive(:persisted?).and_return(true) }

      it { 
        subject
        expect(redis_instance).to have_received(:publish)
      }

    end

    context 'profile is not valid' do
      before(:each){allow(profile).to receive(:persisted?).and_return(false) }

      it { 
        subject
        expect(redis_instance).not_to have_received(:publish)
      }
    end

  end


end
