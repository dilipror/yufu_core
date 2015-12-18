module OnlineHelp
  class Message
    include Mongoid::Document
    include Timestamps::Created
    extend Enumerize

    field :text
    field :owner

    embedded_in :helpdesk_chat

    enumerize :owner, in: [:client, :operator]

    validates_presence_of :text, :owner
  end
end