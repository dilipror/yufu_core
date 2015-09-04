require "yufu_core/engine"
require 'statistic'
require 'statistic/base'
require 'statistic/banners'
require 'statistic/invites'
require 'statistic/link'
require 'searchers/order/verbal_searcher'
require 'i18n/backend/mongoid'
require 'yufu/translation_proxy'
require 'yufu/add_versions_to_i18n_patch'
require 'yufu/mongoid_fields_localized_patch'
require 'yufu/mongoid_fields_patch'
require 'yufu/i18n_mailer_scope'

require 'hash_extension'

require 'humanize/cache'
require 'humanize/humanize'
require 'humanize/lots'

require 'devise/orm/mongoid'
require 'autoinc'
require 'paperclip'
require 'mongoid_paperclip'
require 'state_machine'
require 'mongoid/token'
require 'mongoid_auto_increment'
require 'active_model_serializers'
require 'enumerize'


module YufuCore
end
