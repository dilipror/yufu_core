module YufuSocket
  class ProfileService
    def initialize(profile)
      @profile = profile if profile.persisted?
    end

    def profile_created!
      return unless @profile.present?
      payload = "{\"event\":\"profile_created\" , \"profile_id\":#{@profile.id} }"
      publish!(payload)
    end

    def profile_updated!
      return unless @profile.updated_at?
      payload = "{\"event\":\"profile_updated\" , \"profile_id\":#{@profile.id} }"
      publish!(payload)
    end  

    private
    def publish!(payload)
      redis.publish("websockets.profile", payload) 
    end

    def redis
      Redis.new
    end

  end
end