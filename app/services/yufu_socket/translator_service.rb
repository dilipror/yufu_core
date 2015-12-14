module YufuSocket
  class TranslatorService < BaseRedisService
    
    CHANNEL = "websockets.translator"
    attr_reader :profile,:channel

    def initialize(profile, channel = CHANNEL)
      @profile = profile if profile.persisted?
      @channel = channel
    end

    def profile_updated!
      return unless profile.valid?
      payload = "{\"event\":\"profile_updated\" , \"profile\":#{profile.to_json} }"
      publish!(payload)
    end  

    private
    def publish!(payload)
      connection.publish(channel, payload) 
    end

  end
end