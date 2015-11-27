$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "yufu_core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "yufu_core"
  s.version     = YufuCore::VERSION
  s.authors     = ["Your name"]
  s.email       = ["Your email"]
  s.homepage    = "http://yufu.net"
  s.summary     = "Summary of YufuCore."
  s.description = "Description of YufuCore."

  s.files = Dir["{app,config,db,lib}/**/*", "spec/factories/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "> 4.2.0"
  s.add_dependency "mongoid", "> 4.0.0"
  s.add_dependency "bson"
  s.add_dependency "mongoid-autoinc"
  s.add_dependency "mongoid-paperclip"
  s.add_dependency "enumerize"
  s.add_dependency "mongoid_token"
  s.add_dependency "devise"
  s.add_dependency "cancancan"
  s.add_dependency "iso-639"
  s.add_dependency "active_model_serializers"
  s.add_dependency "oj"
  s.add_dependency "state_machines-mongoid"
  s.add_dependency "sidekiq"
  s.add_dependency "money-rails"
  s.add_dependency "eu_central_bank"
  s.add_dependency "slim-rails"
  s.add_dependency "mongoid_auto_increment"
  s.add_dependency "paperclip", "< 4.3"
  s.add_dependency "wicked_pdf"
  s.add_dependency "wkhtmltopdf-binary"
  s.add_dependency "mongoid_paranoia"
  s.add_dependency "faye-websocket", '0.10.1'
end
