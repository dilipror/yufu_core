require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)
require "yufu_core"

module TestApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.available_locales = [:af, :ar, :az, :bg, :bn, :bs, :ca, :cs, :cy, :da, :de, :el, :en, :eo, :es, :et,
                                     :eu, :fa, :fi, :fr, :gl, :he, :hi, :hr, :hu, :id, :is, :it, :ja, :km, :kn, :ko, :lo,
                                     :lt, :lv, :mk, :mn, :ms, :nb, :ne, :nl, :nn, :or, :pl, :pt, :rm, :ro, :ru, :sk, :sl,
                                     :sr, :sv, :sw, :ta, :th, :tl, :tr, :uk, :ur, :uz, :vi, :wo,
                                     'zh-CN', 'zh-HK', 'zh-TW', 'zh-YUE', 'cn-pseudo']

    config.host = 'localhost:3000'
    config.action_mailer.default_url_options = { host: config.host }
    config.action_mailer.asset_host = 'http://localhost:3000'


    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {:address => "localhost", :port => 1025}
    ActionMailer::Base.default from: 'Yufu <postmaster@mg.yufu.net>'
    config.active_job.queue_adapter = :test
  end
end

