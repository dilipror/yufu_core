module YufuSocket   
  class BaseRedisService
    def connection
	    #  if !(defined?(@@connection) && @@connection)
	    #    @@connection = Redis.new(:url => "redis://#{YufuCore.config.redis_host}:#{YufuCore.config.redis_port}/#{YufuCore.config.redis_db}")
	    #  end
	    #  @@connection
    	Redis.new(:url => "redis://#{YufuCore.config.redis_host}:#{YufuCore.config.redis_port}/#{YufuCore.config.redis_db}")
   	end 	
   end
end   