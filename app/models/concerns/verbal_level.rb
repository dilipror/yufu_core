module VerbalLevel
  extend ActiveSupport::Concern

  included do
    extend Enumerize

    field :level, type: Integer, default: 1
    enumerize :level, in: Order::Verbal::TRANSLATION_LEVELS
  end
end