module Order
  class Verbal < Base
    TRANSLATION_LEVELS = {guide: 1, business: 2, expert: 3}

    include VerbalLevel

    GENDERS = ['male', 'female']
    GOALS   = ['business', 'entertainment']
    DEFAULTCOST = 115.0
    DEFAULT_SURCHARGE_NEAR_CITY = 430.0 # CNY


    field :translation_level
    field :include_near_city, type: Mongoid::Boolean, default: false
    field :goal
    field :want_native_chinese, type: Mongoid::Boolean, default: false
    field :do_not_want_native_chinese, type: Mongoid::Boolean, default: false
    field :update_time, type: DateTime
    field :greeted_at_hour,   type: Integer, default: 7
    field :greeted_at_minute, type: Integer, default: 0
    field :meeting_in
    field :additional_info
    field :paid_time,         type: Time

    belongs_to :location, class_name: 'City'
    belongs_to :translator_native_language, class_name: 'Language'
    belongs_to :native_language,            class_name: 'Language'
    belongs_to :language

    embeds_one :airport_pick_up, class_name: 'Order::AirportPickUp'

    embeds_many :reservation_dates,  class_name: 'Order::ReservationDate'
    has_many :translators_queues, class_name: 'Order::Verbal::TranslatorsQueue', dependent: :destroy
    has_many :offers,             class_name: 'Order::Offer',   dependent: :destroy

    has_one  :main_language_criterion,     class_name: 'Order::LanguageCriterion', inverse_of: :main_socket,    dependent: :destroy
    has_many :reserve_language_criterions, class_name: 'Order::LanguageCriterion', inverse_of: :reserve_socket, dependent: :destroy

    has_and_belongs_to_many :directions

    accepts_nested_attributes_for :reserve_language_criterions, :reservation_dates, allow_destroy: true
    accepts_nested_attributes_for :main_language_criterion, :airport_pick_up

    delegate :name, to: :location, prefix: true, allow_nil: true

    has_notification_about :updated, message: 'notifications.order_updated',
                           observers: :subscribers

    has_notification_about :looking_for_int,
                           message: 'notifications.looking_for_int',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.we_are_looking(user).deliver
                           end

    has_notification_about :looking_for_int_before_24,
                           message: 'notifications.looking_for_int_before_24',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.we_are_looking_before_24(user).deliver
                           end


    has_notification_about :reminder_for_interpreter_24,
                           observers: -> (order) {order.primary_offer},
                           message: 'notification.change_status_main_intrp',
                           mailer: -> (user, order) do
                             NotificationMailer.reminder_for_backup_interpreter_24 user
                           end

    has_notification_about :reminder_for_main_interpreter_36,
                           observers: -> (order) {order.primary_offer},
                           message: 'notification.change_status_main_intrp',
                           mailer: -> (user, order) do
                             NotificationMailer.reminder_for_main_interpreter_36 user
                           end

    has_notification_about :reminder_to_the_client_48,
                           observers: -> (order) {order.primary_offer},
                           message: 'notification.appointment_with_interpreter',
                           mailer: -> (user, order) do
                             NotificationMailer.reminder_to_the_client_48 user, order
                           end

    has_notification_about :check_dates,
                           message: 'notifications.check_dates',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.check_dates(user, order).deliver
                           end

    has_notification_about :cancel,
                           message: 'notifications.cancel',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.cancel(user).deliver
                           end

    validates_length_of :reservation_dates, minimum: 1, if: :persisted?
    validates_presence_of :location, if: :persisted?
    validate :assign_reservation_to_criterion, if: -> (o) {o.step == 2}
    validates_length_of :offers, maximum: 2, unless: ->(order) {order.will_begin_less_than?(36.hours)}

    before_save :set_update_time, :update_notification, :check_dates, :set_private, :set_langvel
    before_create :set_main_language_criterion
    after_save :create_additional_services

    scope :paid_orders, -> { where state: :in_progress}
    scope :wait_offer,  -> { where state: :wait_offer }
    scope :unpaid,      -> { where :state.in => [:new, :paying] }
    scope :in_progress, -> (profile) do
      default_scope_for(profile).where :state.in => [:in_progress, :additional_paying],
                                       connected_method_for(profile) => profile
    end
    scope :wait_offer, -> {where state: :wait_offer}
    scope :close,       -> (profile) do
      default_scope_for(profile).where :state.in => [:close, :rated], connected_method_for(profile) => profile
    end

    state_machine initial: :new do

      before_transition on: :process do |order|
        order.update assignee: order.try(:primary_offer).try(:translator)
        order.notify_about_processing
        order.try :set_busy_days
        true
      end

      before_transition on: :paid do |order|
        OrderVerbalQueueFactoryWorker.perform_async order.id, I18n.locale
        OrderWorkflowWorker.perform_in 24.hours, order.id, 'after_24'
        OrderWorkflowWorker.perform_in 12.hours, order.id, 'after_12'
        OrderWorkflowWorker.perform_in (order.first_date_time - 60.hours) - Time.now, order.id, 'before_60'
        OrderWorkflowWorker.perform_in (order.first_date_time - 48.hours) - Time.now , order.id, 'before_48'
        OrderWorkflowWorker.perform_in (order.first_date_time - 36.hours) - Time.now , order.id, 'before_36'
        OrderWorkflowWorker.perform_in (order.first_date_time - 24.hours) - Time.now, order.id, 'before_24'
        OrderWorkflowWorker.perform_in (order.first_date_time -  4.hours) - Time.now , order.id, 'before_4'
        order.update paid_time: Time.now
      end

    end

    def additional_cost(currency = nil)
      0
    end

    def can_send_primary_offer?
      #offers.primary.empty?
    end

    def can_send_secondary_offer?
      #offers.secondary.empty?
    end

    def original_price
      reservation_price = reservation_dates.to_a.inject(0) { |sum, n| sum + n.original_price }
      price = 0
      if include_near_city && there_are_translator_with_surcharge?
        price = reservation_price + DEFAULT_SURCHARGE_NEAR_CITY
      else
        price = reservation_price
      end
      BigDecimal.new price
    end

    def there_are_translator_with_surcharge?
      CityApprove.where(city: location, with_surcharge: true).each do |apr_city|
        ln = language || main_language_criterion.language
        tmp = apr_city.translator.services.where language: ln, :level.gte => level_value
        return true if tmp.count > 0
      end
      false
    end

    # Deprecated
    def general_cost(currency = nil)
      reservation_dates.to_a.inject(0) { |sum, n| sum + n.cost(currency) }
    end

    def different_dates
      dates = []
      reservation_dates.each do |date|
        unless dates.map{|d| d.date}.include? date.date || !date.fake?
          dates << date
        end
      end
      dates
    end

    def primary_offer
      offers.state_new.first
    end

    def secondary_offer
      offers.state_new[1]
    end

    def supported_by?(translator)
      return false unless translator.is_a? Profile::Translator
      translator.can_process_order? self
    end

    def first_date_time
      if reservation_dates.first.present?
        reservation_dates.first.date.change({hour: greeted_at_hour, min: greeted_at_minute})
      else
        Time.now
      end
    end


    def paid_ago?(time)
      (Time.now - paid_time) >= time if paid_time.present?
    end

    def will_begin_less_than?(time)
      (first_date_time.to_time - Time.now) <= time && (first_date_time.to_time - Time.now) > 0
    end

    def will_begin_at?(time)
      # TODO: implement
    end

    def has_offer?
      offers.new_or_confirmed.count > 0
    end

    private
    def create_additional_services
      create_airport_pick_up if airport_pick_up.nil?
    end

    def set_langvel
      unless main_language_criterion.nil?
        self.language = main_language_criterion.language if language.nil?
        self.level = main_language_criterion.level if level.nil?
      end
    end

    def first_date
      reservation_dates.order('date acs').first.date || Time.now
    end

    def hours_to_meeting
      if greeted_at_hour
        add = 1.hour * greeted_at_hour
      else
        add = 0
      end

      ((Time.parse((first_date).to_s) - Time.now + add).to_i / 1.hour).round + 1
    end

    def set_main_language_criterion
      build_main_language_criterion if main_language_criterion.nil?
    end

    def set_private
      if translator_native_language && main_language_criterion
        self.is_private = translator_native_language.office_has_local_translators? &&
            main_language_criterion.language.is_supported_by_office?
      end
      true
    end

    def office
      location.try(:office) || super
    end

    def set_update_time
      unless state == 'new'
        write_attribute :update_time, Time.now
      end
    end

    def can_update?
      state == 'close' ? false : (update_time.nil? ? true : (DateTime.now - update_time) >= 1)
      # state == 'new' ? true : (update_time.nil? ? true : (DateTime.now - update_time) >= 1)
    end
    alias :can_update :can_update?

    def check_dates
      reservation_dates.each do |date|
        if  main_language_criterion.present? &&
            date.available?(main_language_criterion.language, nil, main_language_criterion.level) &&
            !date.is_confirmed
          date.write_attribute :is_confirmed, true
        end
      end
    end

    def set_busy_days
      reservation_dates.confirmed.each do |date|
        assignee.busy_days << BusyDay.new(date: date.date, order_verbal: self.id)
      end
      assignee.save
    end

    def update_notification
      # unless state=='new'
      #   notify_about_updated
      # end
    end

    def subscribers
      offers.map &:translator
    end

    # TODO move all search logic to VerbalSearcher
    def self.available_for(profile)
      ::Searchers::Order::VerbalSearcher.new(profile).search  if profile.is_a? Profile::Translator
    end

    def assign_reservation_to_criterion
      f = false
      reservation_dates.each {|d| f = true if d.is_confirmed}
      unless f
        errors.add :reservation_dates, 'at least one should be assigns to language'
      end
    end

    def senior
      main_language_criterion.language.try :senior
    end

    # Need refactor with new cash system
    def close_cash_flow
      unless self.is_private
        price_to_members = self.price * 0.95
        self.create_and_execute_transaction(Office.head, self.assignee.user.overlord, price_to_members * 0.015)
        # senior = self.location.senior
        senior = main_language_criterion.language.senior
        if senior == self.assignee
          self.create_and_execute_transaction(Office.head, self.assignee.user, price_to_members*0.7)
        else
          self.create_and_execute_transaction(Office.head, self.assignee.user, price_to_members*0.7)
          self.create_and_execute_transaction(Office.head, senior.user, price_to_members*0.03)
        end
      end
    end

    def paid_cash_flow
      self.create_and_execute_transaction owner.user, Office.head, price
    end

    def paying_items
      paying_items_per_day + overtime_paying_items + surcharge_paying_items
    end

    private
    def paying_items_per_day
      lalelo = "#{language.name}, #{I18n.t('mongoid.attributes.order/verbal.level')} - #{I18n.t(level, scope: 'enums.order/verbal.translation_levels')}, #{I18n.t('mongoid.attributes.order/verbal.location')} - #{location.name}"
      reservation_dates.map do |rd|
        if rd.hours < 8
          comment = " #{rd.hours} #{I18n.t('frontend.order.verbal.hours')} * 1.5"
        else
          comment = " #{rd.hours}  #{I18n.t('frontend.order.verbal.hours')}"
        end
        {
            cost: rd.original_price_without_overtime,
            description: "#{lalelo}. #{I18n.t('frontend.order.verbal.for_date')} #{rd.date.strftime('%Y-%m-%d') + comment}"
        }
      end
    end

    def overtime_paying_items
      overtime = reservation_dates.confirmed.offset(1).inject(0) {|sum, rd| sum + rd.overtime_price}
      overtime += reservation_dates.first.overtime_price is_first_date: true, work_start_at: greeted_at_hour
      if overtime > 0
        [{cost: overtime, description: "#{I18n.t('frontend.order.verbal.overtime')}"}]
      else
        []
      end
    end

    def surcharge_paying_items
      if include_near_city && there_are_translator_with_surcharge?
        eu_bank = ExchangeBank.instance
        [{cost: eu_bank.exchange(DEFAULT_SURCHARGE_NEAR_CITY * 100, 'CNY', Currency.current_currency), description: I18n.t('mongoid.surcharge')}]
      else
        []
      end
    end
  end
end