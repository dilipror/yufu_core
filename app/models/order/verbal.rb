module Order
  class Verbal < Base

    TRANSLATION_LEVELS = %w(guide business expert)

    GENDERS = ['male', 'female']
    GOALS   = ['business', 'entertainment']
    DEFAULTCOST = 115.0


    field :translation_level
    field :include_near_city, type: Mongoid::Boolean, default: false
    field :goal
    field :want_native_chinese, type: Mongoid::Boolean, default: false
    field :do_not_want_native_chinese, type: Mongoid::Boolean, default: false
    field :update_time, type: DateTime
    field :level
    field :greeted_at_hour, type: Integer
    field :greeted_at_minute, type: Integer
    field :meeting_in
    field :additional_info

    belongs_to :location, class_name: 'City'
    belongs_to :translator_native_language, class_name: 'Language'
    belongs_to :native_language,            class_name: 'Language'


    belongs_to :language
    has_many   :reserve_language_criterions, class_name: 'Order::LanguageCriterion', inverse_of: :reserve_socket, dependent: :destroy
    has_one    :main_language_criterion,      class_name: 'Order::LanguageCriterion', inverse_of: :main_socket, dependent: :destroy

    embeds_many :reservation_dates,  class_name: 'Order::ReservationDate'
    has_many :translators_queues, class_name: 'Order::Verbal::TranslatorsQueue', dependent: :destroy

    accepts_nested_attributes_for :reserve_language_criterions,  allow_destroy: true
    accepts_nested_attributes_for :main_language_criterion
    accepts_nested_attributes_for :reservation_dates,            allow_destroy: true

    has_and_belongs_to_many :directions
    has_many :offers,      class_name: 'Order::Offer',   dependent: :destroy

    delegate :name, to: :location, prefix: true, allow_nil: true


    has_notification_about :ready_for_processing, message: 'notifications.ready_for_processing',
                           observers: -> (order) { Profile::Translator.support_order(order)}
    has_notification_about :updated, message: 'notifications.order_updated',
                           observers: :subscribers

    has_notification_about :reminder_for_interpreter_24,
                           observers: -> (order) {order.primary_offer},
                           message: 'notification.change_status_main_intrp',
                           mailer: -> (user, offer) do
                             NotificationMailer.reminder_for_backup_interpreter_24 user
                           end

    has_notification_about :reminder_for_interpreter_36,
                           observers: -> (order) {order.primary_offer},
                           message: 'notification.change_status_main_intrp',
                           mailer: -> (user, offer) do
                             NotificationMailer.reminder_for_backup_interpreter_36 user
                           end

    has_notification_about :reminder_to_the_client_48,
                           observers: -> (order) {order.primary_offer},
                           message: 'notification.appointment_with_interpreter',
                           mailer: -> (user, offer) do
                             NotificationMailer.reminder_to_the_client_48 user
                           end


    validates_length_of :reservation_dates, minimum: 1, if: :persisted?
    validates_presence_of :location, if: :persisted?
    validate :assign_reservation_to_criterion, if: -> (o) {o.step == 2}
    validates_inclusion_of :level, in: Order::Verbal::TRANSLATION_LEVELS, if: ->{step > 1}

    before_save :set_update_time, :update_notification, :check_dates, :set_private, :set_langvel
    before_create :set_main_language_criterion

    scope :open,        -> (profile) { default_scope_for(profile).where state: :wait_offer }
    scope :paying,      -> (profile) { profile.orders.where :state.in => [:new, :paying] }
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
      end
    end

    def additional_cost(currency = nil)
      0
    end

    def can_send_primary_offer?
      offers.primary.empty?
    end

    def can_send_secondary_offer?
      offers.secondary.empty?
    end

    def original_price
      reservation_price = reservation_dates.to_a.inject(0) { |sum, n| sum + n.original_price }
      price = 0
      if include_near_city && there_are_translator_with_surcharge?
        price = reservation_price + 310
      else
        price = reservation_price
      end
      BigDecimal.new price
    end

    def there_are_translator_with_surcharge?
      CityApprove.where(city: location, with_surcharge: true).each do |apr_city|
        ln = language || main_language_criterion.language
        tmp = apr_city.translator.services.where language: ln, level: level
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
      offers.primary.first
    end

    def secondary_offer
      offers.secondary.first
    end

    def supported_by?(translator)
      return false unless translator.is_a? Profile::Translator
      translator.can_process_order? self
    end

    private

    def set_langvel
      unless main_language_criterion.nil?
        write_attribute(:language_id, main_language_criterion.language_id) if language.nil?
        write_attribute(:level, main_language_criterion.level) if level.nil?
      end
    end

    def first_date
      reservation_dates.order('date acs').first.date
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

    def self.skip_unconfirmed_offers
      where(state: 'wait_offer').each do |order|
          order.offers.where(status: 'primary').first.update status: 'secondary'
      end
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
      unless state=='new'
        notify_about_updated
      end
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

    def first_day_work_time(rd)
      begins_work_hour = [7, greeted_at_hour].max
      ends_work_hour = [21, greeted_at_hour+rd.hours].min
      work_hours = [ends_work_hour - begins_work_hour, 8].min
      coef = rd.hours < 8 ? 1.5 : 1
      if work_hours > 0
        rd.simple_price_for_hours(work_hours) * coef
      else
        0
      end
    end

    def first_day_overtime(rd)
      coef = rd.hours < 8 ? 1.5 : 1
      rd.simple_price_for_hours(overtime_hours(rd)) * 1.5 * coef
    end

    def overtime_hours(rd)
      begins_work_hour = [7, greeted_at_hour].max
      ends_work_hour = [21, greeted_at_hour+rd.hours].min
      extra_hours = [0, ends_work_hour - begins_work_hour - 8].max
      extra_hours_before = [0, [greeted_at_hour + rd.hours, 7].min - greeted_at_hour].max
      extra_hours_after = [0, greeted_at_hour + rd.hours - [21, greeted_at_hour].max].max
      extra_hours + extra_hours_before + extra_hours_after
    end

    def paying_items
      res = []
      overtime = 0
      over_comment = '('
      reservation_dates.each do |rd|
        if greeted_at_hour.present? && rd == reservation_dates.first
          begins_work_hour = [7, greeted_at_hour].max
          ends_work_hour = [21, greeted_at_hour+rd.hours].min
          work_hours = [ends_work_hour - begins_work_hour, 8].min
          overtime += first_day_overtime(reservation_dates.first)
          if overtime
            over_comment += " #{overtime_hours(rd)} +"
          end
          comment = " 8 #{I18n.t('frontend.order.verbal.hours')}"
          lalelo = "#{language.name}, #{I18n.t('mongoid.attributes.order/verbal.level')} - #{level}, #{I18n.t('mongoid.attributes.order/verbal.location')} - #{location.name}"
          if work_hours > 0
            res << {cost: first_day_work_time(reservation_dates.first), description: "#{lalelo}. #{I18n.t('frontend.order.verbal.for_date')} #{rd.date.strftime('%Y-%m-%d') + comment}"}
          end
        else
          if rd.original_price_without_overtime > 0
            comment = " 8 #{I18n.t('frontend.order.verbal.hours')}"
            if rd.hours < 8
              comment = " #{rd.hours} #{I18n.t('frontend.order.verbal.hours')} * 1.5"
            end
            lalelo = "#{language.name}, #{I18n.t('mongoid.attributes.order/verbal.level')} - #{level}, #{I18n.t('mongoid.attributes.order/verbal.location')} - #{location.name}"
            res << {cost: rd.original_price_without_overtime, description: "#{lalelo}. #{I18n.t('frontend.order.verbal.for_date')} #{rd.date.strftime('%Y-%m-%d') + comment}"}
            overtime += rd.overtime_price
            if rd.hours > 8
              over_comment += " #{rd.hours - 8} +"
            end
          end
        end
      end
      if include_near_city && there_are_translator_with_surcharge?
        eu_bank = ExchangeBank.instance
        res << {cost: eu_bank.exchange(5000, 'USD', Currency.current_currency), description: I18n.t('mongoid.surcharge')}
      end
      over_comment.gsub! /\+$/, ''
      over_comment += " ) #{I18n.t('frontend.order.verbal.hours')}"
      if overtime > 0
        res << {cost: overtime, description: "#{I18n.t('frontend.order.verbal.overtime')} #{over_comment} * 1.5"}
      end
      res
    end

  end
end