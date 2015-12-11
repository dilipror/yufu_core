module OnlineHelp
  class Chat
    include Mongoid::Document
    include Mongoid::Timestamps

    field :email, type: String
    field :is_active, type: Mongoid::Boolean, default: true

    belongs_to :localization
    belongs_to :operator, class_name: 'User'

    embeds_many :messages, class_name: 'OnlineHelp::Message'

    scope :active,    -> {where is_active: true}
    scope :in_active, -> {where :is_active.ne => true}
    scope :free, -> {active.where operator_id: nil}

    validates_presence_of :localization, :email
  end
end