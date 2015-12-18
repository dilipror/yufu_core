module YufuSocket
  class ProfileService < BaseRedisService

    CHANNEL = "websockets.profile"
    attr_reader :profile, :channel

    def initialize(profile , channel = CHANNEL)
      @profile = profile if profile.persisted?
      @channel = channel
    end

    def profile_created!
      return unless profile.persisted?
      payload = "{\"event\":\"profile_created\" , \"profile\":#{profile.to_json} }"
      publish!(payload)
    end

    def profile_updated!
      return unless profile.valid?
      payload = "{\"event\":\"profile_updated\" , \"profile\":#{profile.to_json} }"
      publish!(payload)
    end  

    def publish!(payload)
      connection.publish(channel, payload) 
    end

  end
end