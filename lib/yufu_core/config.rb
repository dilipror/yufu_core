module YufuCore
  # Class used to initialize configuration object.
  class Config
    attr_accessor :redis_url, :redis_host, :redis_port, :redis_db

    def initialize
      @redis_url = nil # "redis://localhost:6379"	
      @redis_host = "localhost"
      @redis_port = 6379
      @redis_db = 1
    end

  end
end