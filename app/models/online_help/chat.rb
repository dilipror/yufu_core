require 'net/http'

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

    after_create :assign_operator

    validates_presence_of :localization, :email
    validates_format_of :email, :with => /(\A[^-][\w+\-.]*)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    private

    def assign_operator
      raw_url = Rails.application.config.online_help_reassign
      url = URI.parse(raw_url)
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
    end
  end
end