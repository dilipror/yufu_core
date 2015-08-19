module YufuCore
  class Engine < ::Rails::Engine
    initializer 'yufu_core.action_mailer' do |app|
      ActiveSupport.on_load :action_mailer do
        include YufuHelper
        helper YufuHelper
      end
    end

    initializer "yufu_core.factories", :after => "factory_girl.set_factory_paths" do
      FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryGirl)
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end
  end
end
