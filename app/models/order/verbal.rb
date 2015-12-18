module Order
  class Verbal < Base
    TRANSLATION_LEVELS = {guide: 1, business: 2, expert: 3}

    include VerbalLevel
    include OrderVerbalWorkflow

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

    belongs_to :location, class_name: 'City'
    belongs_to :translator_native_language, class_name: 'Language'
    belongs_to :native_language,            class_name: 'Language'
    belongs_to :language

    embeds_one :airport_pick_up, class_name: 'Order::AirportPickUp'
    embeds_one :events_manager, class_name: 'Order::Verbal::EventsManager', cascade_callbacks: true

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

    has_notification_about :we_are_looking_10,
                           message: 'notifications.looking_for_int',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.we_are_looking_10 user
                           end

    has_notification_about :we_are_looking_before_24_11,
                           message: 'notifications.looking_for_int_before_24_11',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.we_are_looking_before_24_11 user
                           end


    has_notification_about :check_dates_5,
                           message: 'notifications.check_dates_5',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.check_dates_5 user, order
                           end

    has_notification_about :cancel_12,
                           message: 'notifications.cancel_12',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.cancel_12 user
                           end
    has_notification_about :cancel_by_owner_delayed_order,
                           message: 'notifications.cancel_delayed_order',
                           observers: :owner,
                           mailer: -> (user, order) do
                             NotificationMailer.cancel_by_user_due_conf_delay_14 user
                           end

    validates_length_of :reservation_dates, minimum: 1, if: :persisted?
    validates_presence_of :location, if: :persisted?
    validate :assign_reservation_to_criterion, if: -> (o) {o.step == 2}
    validates_length_of :offers, maximum: 2, unless: ->(order) {order.will_begin_less_than?(36.hours)}

    before_save :set_update_time, :update_notification, :check_dates, :set_private, :set_langvel
    before_create :set_main_language_criterion, :build_events_manager
    after_save :create_additional_services
    # after_save :notify_about_updated, if: :persisted?

    scope :confirmed, -> {where state: 'confirmed'}
    scope :wait_offer, -> {where :state.in => %w(confirmation_delay wait_offer reconfirm_delay translator_not_found)}
    scope :need_reconfirm, -> {where state: 'need_reconfirm'}
    scope :main_reconfirm_delay, -> {where state: 'main_reconfirm_delay'}
    scope :ready_for_backup_confirmation, -> {where :state.in => %w(main_reconfirm_delay reconfirm_delay)}
    scope :reconfirm_delay, -> {where state: 'reconfirm_delay'}
    scope :confirmation_delay, -> {where state: 'confirmation_delay'}
    scope :translator_not_found, -> {where state: 'translator_not_found'}
    scope :canceled_by_client, -> {where state: 'canceled_by_client'}
    scope :canceled_not_paid, -> {where state: 'canceled_not_paid'}
    scope :canceled_by_yufu, -> {where state: 'canceled_by_yufu'}

    def can_send_primary_offer?
      can_confirm? && primary_offer.nil?
    end

    def can_send_secondary_offer?
      can_confirm? && secondary_offer.nil?
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

    def last_date_time
      if reservation_dates.last.present?
        reservation_dates.last.date
      else
        Time.now
      end
    end

    def will_begin_less_than?(time)
      (first_date_time.to_time - Time.now) <= time && (first_date_time.to_time - Time.now) > 0
    end
    def has_offer?
      offers.new_or_confirmed.count > 0
    end

    def create_additional_services
      create_airport_pick_up if airport_pick_up.nil?
    end

    def set_langvel
      unless main_language_criterion.nil?
        self.language = main_language_criterion.language if language.nil?
        self.level = main_language_criterion.level if level.nil?
      end
    end

    def offer_status_for(profile)
      return 'primary' if offers.where(translator: profile).first.try(:primary?)
      return 'back_up' if offers.where(translator: profile).first.try(:back_up?)
      return nil
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
      return true if in_progress? || ready_for_close?
      close? ? false : (update_time.nil? ? true : (Time.now - update_time) >= 1.day)
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

    def remove_busy_days
      if assignee.present?
        reservation_dates.confirmed.each do |date|
          assignee.busy_days.where(date: date.date).delete_all
        end
        assignee.save
      end
    end

    def update_notification
      # unless state=='new'
      #   notify_about_updated
      # end
    end

    def subscribers
      offers.map &:translator
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