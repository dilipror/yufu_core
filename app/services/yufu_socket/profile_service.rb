module YufuSocket
  class ProfileService
    def initialize(profile)
      @profile = profile if profile.persisted?
      @yufu_redis_server = Redis.new(:url => "redis://#{YufuCore.config.redis_host}:#{YufuCore.config.redis_port}/#{YufuCore.config.redis_db}")
    end

    def profile_created!
      return unless @profile.present?
      payload = "{\"event\":\"profile_created\" , \"profile\":#{@profile.to_json} }"
      publish!(payload)
    end

    def profile_updated!
      return unless @profile.valid?
      payload = "{\"event\":\"profile_updated\" , \"profile\":#{@profile.to_json} }"
      publish!(payload)
    end  

    private
    def publish!(payload)
      @yufu_redis_server.publish("websockets.profile", payload) 
    end

  end
end