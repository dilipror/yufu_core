module OnlineHelp
  class Message
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    extend Enumerize

    field :text
    field :owner

    embedded_in :chat

    enumerize :owner, in: [:client, :operator]

    validates_presence_of :text, :owner
  end
end