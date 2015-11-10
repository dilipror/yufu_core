module Profile
  class Translator < Base
    include Mongoid::Paperclip
    extend Enumerize
    include Filterable
    include Notificable


    field :passport_number
    field :passport_num
    field :passport_country
    field :is_banned, type: Mongoid::Boolean, default: false
    field :custom_city

    # field :state
    field :last_sent_to_approvement, type: DateTime, default: DateTime.yesterday
    # field :one_day_passed, type: Boolean, default: nil

    # field :test, default: nil

    embeds_one :profile_steps_language,  class_name: 'Profile::Steps::LanguageMain', cascade_callbacks: true, validate: false
    embeds_one :profile_steps_service,   class_name: 'Profile::Steps::Service',      cascade_callbacks: true, validate: false
    embeds_one :profile_steps_personal,  class_name: 'Profile::Steps::Personal',     cascade_callbacks: true, validate: false
    embeds_one :profile_steps_contact,   class_name: 'Profile::Steps::Contact',      cascade_callbacks: true, validate: false
    embeds_one :profile_steps_education, class_name: 'Profile::Steps::Education',    cascade_callbacks: true, validate: false
    embeds_many :busy_days

    belongs_to :country_out_of_china, class_name: 'Country'
    belongs_to :city
    belongs_to :province
    belongs_to :country

    has_many :proof_orders,  class_name: 'Order::Written', inverse_of: :proof_reader
    has_many :orders,        class_name: 'Order::Base', inverse_of: :assignee
    has_many :offers,        class_name: 'Order::Offer'
    has_many :services,      class_name: 'Profile::Service', dependent: :destroy
    has_many :city_approves, class_name: 'CityApprove',      dependent: :destroy
    has_many :assigned_languages, class_name: 'Language', inverse_of: :senior, dependent: :nullify
    has_and_belongs_to_many :order_verbal_translators_queues, :class_name => 'Order::Verbal::TranslatorsQueue',
                            inverse_of: :translators
    has_and_belongs_to_many :order_written_translators_queues, :class_name => 'Order::Written::TranslatorsQueue',
                            inverse_of: :translators
    has_and_belongs_to_many :order_written_correctors_queues, :class_name => 'Order::Written::CorrectorsQueue',
                            inverse_of: :translators

    accepts_nested_attributes_for :busy_days, :profile_steps_language, :profile_steps_service, :profile_steps_personal,
                                  :profile_steps_contact, :profile_steps_education, :city_approves
    accepts_nested_attributes_for :services, allow_destroy: true

    # enumerize :visa, in: ['C', 'D', 'F', 'G', 'J1', 'J2', 'L', 'M', 'Q1', 'Q2', 'R', 'S1', 'S2', 'X1', 'X2', 'Z']

    before_create :build_steps
    before_save :build_default_service
    after_create {profile_steps_service.hard_resolve_city}
    before_create {write_attributes country: Country.where(is_china: true).first}

    # filtering
    scope :filter_state, -> (state) {where state: state}

    # TODO implement after realize translator's calendar feature
    scope :free_on, -> (date) do
      ne 'busy_days.date' => date
    end
    scope :approved, -> {where state: 'approved'}

    # Deprecated
    def self.role_translator
      user_ids = User.where(role: :translator).distinct :id
      where(:user_id.in => user_ids).desc(:created_at)
    end

    has_notification_about :approve_translator,
                           observers: :user,
                           message: "profile_approved",
                           mailer: -> (translator, rr) do
                             NotificationMailer.translator_approving_15 translator
                           end,
                           sms: -> (translator, rr) do
                             Yufu::SmsNotification.instance.translator_approving_15 translator
                           end

    state_machine initial: :new do

      state :ready_for_approvement
      state :approved

      before_transition :on => :approve do |translator|
        translator.notify_about_approve_translator
      end

      event :approve do
        transition [:ready_for_approvement] => :approved
      end

      event :approving do
        transition [:new, :approved] => :ready_for_approvement#, if: :one_day_passed?
      end

    end

    # filtering DEPRECATED
    def self.filter_email(email)
      user_ids = User.where(email: /.*#{email}.*/).distinct :id
      # translator_ids = Profile::Translator.where(:user_id.in => user_ids).distinct :id
      where :user_id.in => user_ids
      # Profile::Translator.all
    end


    def self.without_surcharge(city)
      res = []
      city_approve_ids = CityApprove.where(city: city, with_surcharge: false).distinct :id
      Profile::Translator.all.each do |tr|
        res << tr if (tr.city_approves.distinct(:id) & city_approve_ids) != []
      end
      res
    end

    # def self.with_surcharge(city)
    #   city_approves.where city: city, with_surcharge: true
    # end

    def self.chinese
      china_ids = Country.china.distinct :id
      Profile::Translator.where :'profile_steps_language.citizenship_id'.in => china_ids
    end

    #return all translators who work in CITY
    def self.support_languages_in_city (city, include_closest_cities = false)
      city_id = city.is_a?(City) ? city.id : (City.find(city)).id# исправить
      lngs = []
      Translator.each do |tr|
        if tr.profile_steps_service.cities.map(&:id).include?(city_id)
          tr.services.each do |sr|
            lngs << sr.language
          end
        end
        if include_closest_cities
          if tr.profile_steps_service.cities_with_surcharge.map(&:id).include?(city_id)
            tr.services.each do |sr|
              lngs << sr.language
            end
          end
        end
      end
      return lngs.uniq
    end

    def support_correcting_written_order?(order)
      services.where(written_approves: true).each do |s|
        if /Corrector/.match(s.written_translate_type)
          return true if order.translation_language_id == s.language.id || order.original_language_id == s.language.id
        end
      end
      false
    end

    def support_written_order?(order)
      services.where(written_approves: true).each do |s|
        if /From/.match(s.written_translate_type)
          return true if order.translation_language_id == s.language.id
        end
        if /To|to/.match(s.written_translate_type)
          return true if order.original_language_id == s.language.id
        end
      end
      false
    end



    def self.support_correcting_written_order(order)
      correctors_ids = Profile::Service.where(written_translate_type: /.*Corrector.*/).distinct :translator_id
      support_written_order(order).where(:id.in => correctors_ids)
    end

    def self.support_written_order(order)
      language = order.original_language.is_chinese? ? order.translation_language : order.original_language
      coop = order.original_language.is_chinese? ? 'From' : 'To'
      ids_from_service = Profile::Service.written_approved.support_cooperation(coop).where(language: language).distinct(:translator_id)
      where :id.in => ids_from_service, state: 'approved'
    end

    def self.support_order(order)
      support_services order.language, order.location, order.level
    end

    def self.support_services(language, city, level)
      int_level = level.is_a?(Integer) ? level : Order::Verbal::TRANSLATION_LEVELS[level.to_sym]
      ids_from_service  = Profile::Service.not_only_written
                                          .approved.where(language: language,
                                                          :level.gte => int_level).distinct(:translator_id)
      ids_from_location = CityApprove.approved.where(city: city).distinct(:translator_id)
      where :id.in => (ids_from_service & ids_from_location)
    end

    def chinese?
      profile_steps_language.citizenship.try(:is_china?) || false
    end

    def can_proof_read?(language)
      serv = services.written_approved.where(language: language)
      unless serv.empty?
        return serv.first.written_translate_type.include? 'Corrector'
      end
      false
    end


    def one_day_passed?
      (DateTime.now - last_sent_to_approvement).to_i >= 1
    end


    def all_is_approved?
      return false if services.count == 0
      services.each   {|s| return false unless s.is_approved}
      educations.each {|e| return false unless e.is_approved}
      true
    end

    def authorized?
      services.approved.count > 0 && city_approves.approved.count > 0
    end

    def busy?(dates)
      dates = [dates] unless dates.is_a? Array
      busy_days.where(:date.in => dates).count > 0
    end

    def status
      'dev'
      # return state.to_s         if ['new', 'reopen'].include? state.to_s
      # return 'partial_approved' if state.to_s == 'approving' && partial_approved
      # return 'approved'         if state.to_s == 'approving' && all_approved
      # return 'approving'        if state.to_s == 'approving' && !partial_approved && !all_approved
    end

    def can_process_order?(order)
      city_approves.approved.where(city_id: order.location.id).any? &&
          services.approved.where(language_id: order.language.id, :level.gte => order.level_value).any?
    end


    protected

    def build_steps
      build_profile_steps_language  if profile_steps_language.nil?
      build_profile_steps_service   if profile_steps_service.nil?
      build_profile_steps_personal  if profile_steps_personal.nil?
      build_profile_steps_contact   if profile_steps_contact.nil?
      build_profile_steps_education if profile_steps_education.nil?
    end

    def build_default_service
      build_steps if profile_steps_language.nil?
      services.build language: profile_steps_language.native_language if services.empty? &&
          profile_steps_language.native_language.present? &&
          !profile_steps_language.native_language.is_chinese?
      true
    end

  end
end