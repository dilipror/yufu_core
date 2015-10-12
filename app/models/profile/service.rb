module Profile
  class Service
    include Mongoid::Document
    include Approvable
    include Filterable
    include VerbalLevel

    field :verbal_price,           type: BigDecimal
    field :written_price,          type: BigDecimal
    field :corrector,              type: Mongoid::Boolean
    field :claim_senior,           type: Mongoid::Boolean, default: false
    field :written_approves,       type: Mongoid::Boolean, default: false
    field :local_expert,           type: Mongoid::Boolean, default: false
    field :only_written,           type: Mongoid::Boolean, default: false
    field :written_translate_type
    field :additions
    field :certificate

    belongs_to :language
    belongs_to :translator, class_name: 'Profile::Translator'

    has_one :level_up_request, class_name: 'Profile::LevelUpRequest', dependent: :destroy

    validates_presence_of :language
    validate :present_written_translate_type

    scope :only_written, -> {where only_written: true}
    scope :not_only_written, -> {where :only_written.ne => true}
    scope :written_approved, -> {where :written_approves => true}

    after_save :change_translator_state, if: -> { (level_changed? || written_translate_type_changed?) &&
                                           translator.try(:state) == 'approved' }


    after_destroy :change_translator_state, if: -> {translator.try(:state) == 'approved'}
    after_create  :change_translator_state, if: -> {translator.try(:state) == 'approved'}

    def self.support_cooperation(type)
      types = ['From-To Chinese']
      types << 'From Chinese' if type.include?('From')
      types << 'To Chinese' if type.include?('To')
      where :written_translate_type.in => types
    end

    def change_translator_state
      translator.try :approving
      translator.update_attributes total_approve: false
    end

    #filtering
    def self.filter_language(language_id)
      Profile::Service.where language_id: language_id
    end

    def self.filter_level(level)
      Profile::Service.where level: level
    end

    def self.filter_email(email)
      user_ids = User.where(email: /.*#{email}.*/).distinct :id
      translator_ids = Profile::Translator.where(:user_id.in => user_ids).distinct :id
      Profile::Service.where :translator_id.in => translator_ids
    end



    def present_written_translate_type
      if written_approves && written_translate_type.blank?
        errors[:written_approves] << "can't be true when written_translate_type is empty"
      end
    end

    def can_make_senior?
      claim_senior? && language.senior.nil?
    end

    def make_senior
      if can_make_senior?
        language.update senior: translator
        true
      else
        false
      end
    end

    def name
      "#{language.try(:name)} | lvl: #{level}"
    end

    def senior?
      language.try(:senior) == translator
    end
    alias :is_senior :senior?

    def owner?(user)
      false if translator.nil?
      user == translator.user
    end

    def can_update_and_destroy?
      !(written_approves || is_approved)
    end
  end
end