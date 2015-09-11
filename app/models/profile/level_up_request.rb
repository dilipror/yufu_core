module Profile
  class LevelUpRequest
    include Mongoid::Document
    extend Enumerize


    field :from, type: Integer
    field :to,   type: Integer

    belongs_to :service, class_name: 'Profile::Service'

    # enumerize :from, :to, in: Order::Verbal::TRANSLATION_LEVELS

    validates_presence_of :from, :to, :service

  end
end