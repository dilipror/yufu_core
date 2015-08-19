$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "yufu_core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "yufu_core"
  s.version     = YufuCore::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of YufuCore."
  s.description = "TODO: Description of YufuCore."

  s.files = Dir["{app,config,db,lib}/**/*", "spec/factories/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.0.13"
  s.add_dependency "mongoid", "~> 4.0.2"
  s.add_dependency "bson"
  s.add_dependency "mongoid-autoinc"
  s.add_dependency "mongoid-paperclip"
  s.add_dependency "enumerize"
  s.add_dependency "mongoid_token"
  s.add_dependency "devise"
  s.add_dependency "cancancan"
  s.add_dependency "iso-639"
  s.add_dependency "active_model_serializers", "0.9.0"
  s.add_dependency "oj"
  s.add_dependency "state_machine"
  s.add_dependency "sidekiq"
  s.add_dependency "money-rails"
  s.add_dependency "eu_central_bank"
  s.add_dependency "slim-rails"
  s.add_dependency "mongoid_auto_increment"
  s.add_dependency "paperclip", "< 4.3"
end
