module Profile
  class LevelUpRequest
    include Mongoid::Document
    extend Enumerize


    field :from, type: Integer
    field :to,   type: Integer
    field :under_consideration, type: Boolean, default: false

    belongs_to :service, class_name: 'Profile::Service'

    enumerize :to,   in: Order::Verbal::TRANSLATION_LEVELS
    enumerize :from, in: Order::Verbal::TRANSLATION_LEVELS

    validates_presence_of :from, :to, :service
    after_save :check_level_up, if: -> {state != 'new'}
    after_create :set_profile_state

    def set_profile_state
      if service.translator.present?
        service.translator.approving if service.translator.can_approving?
      end
    end


    state_machine initial: :new do
      state :rejected
      state :approved

      event :reject do
        transition new: :rejected
      end

      event :approve do
        transition new: :approved
      end
    end

    def check_level_up
      if state == 'approved'
        service.update_attributes level: to
      end
      destroy
    end

  end
end