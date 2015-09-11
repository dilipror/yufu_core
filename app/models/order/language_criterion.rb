module Order
  class LanguageCriterion
    include Mongoid::Document
    include Mongoid::Timestamps
    include Priced
    include VerbalLevel

    belongs_to :language

    belongs_to :main_socket,    class_name: 'Order::Verbal', inverse_of: :main_language_criterion
    belongs_to :reserve_socket, class_name: 'Order::Verbal', inverse_of: :reserve_language_criterions

    validate :only_one_socket_present
    validates_presence_of :language_id, if: :persisted?
    # validates_presence_of :language

    def original_price
      return 0 if language.nil?
      language.verbal_price(level)
    end

    protected
    def only_one_socket_present
      errors[:reserve_socket] << 'only one socket can be presented' if main_socket.present? && reserve_socket.present?
    end
  end
end