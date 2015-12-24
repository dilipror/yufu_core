module YufuSocket   
  class BaseRedisService
    def connection
      #  if !(defined?(@@connection) && @@connection)
      #    @@connection = Redis.new(:url => "redis://#{YufuCore.config.redis_host}:#{YufuCore.config.redis_port}/#{YufuCore.config.redis_db}")
      #  end
      #  @@connection

      if YufuCore.config.redis_url.blank?
        Redis.new(:host => YufuCore.config.redis_host, :port => YufuCore.config.redis_port, :db => YufuCore.config.redis_db)
      else
        Redis.new(:url => YufuCore.config.redis_url)
      end
      
    end   
   end
end   