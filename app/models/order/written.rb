module Order
  class Written < Base
    include Mongoid::Paperclip

    before_create :build_relations

    TYPES  = %w(text document media)
    LEVELS = %w(translate_and_correct translate)
    WORDS_PER_DAY_TRANS = 1500.0
    WORDS_PER_DAY_PROOF = 4500.0
    CHARS_PER_DAY_TRANS = 2400.0
    CHARS_PER_DAY_PROOF = 7200.0
    DOCS_PER_DAY = 8.0

    field :translation_type
    field :quantity_for_translate, type: Integer, default: 0
    field :level
    field :second_level

    has_mongoid_attached_file :translation
    do_not_validate_attachment_file_type :translation

    has_notification_about :correct, observers: ->(order){[order.owner, order.senior]}, message: 'notifications.correcting_order'
    has_notification_about :control, observers: ->(order){[order.owner, order.senior]}, message: 'notifications.control_order'
    has_notification_about :finish, observers: :owner, message: 'notifications.done_order'
    has_notification_about :cancellation_by_yufu,
                           message: 'notifications.cancel_by_yufu',
                           observers: -> (order) {order.owner.user},
                           mailer: -> (user, order) do
                             NotificationMailer.cancellation_by_yufu(user).deliver
                           end

    belongs_to :original_language,                   class_name: 'Language'
    belongs_to :translation_language,                class_name: 'Language'
    belongs_to :order_type,                          class_name: 'Order::Written::WrittenType'
    belongs_to :order_subtype,                       class_name: 'Order::Written::WrittenSubtype'
    belongs_to :proof_reader,                        class_name: 'Profile::Translator'#, inverse_of: :proof_orders

    has_many :translators_queues, class_name: 'Order::Written::TranslatorsQueue', dependent: :destroy
    has_many :correctors_queues,  class_name: 'Order::Written::CorrectorsQueue', dependent: :destroy

    has_and_belongs_to_many :available_languages,    class_name: 'Language'
    has_and_belongs_to_many :attachments, dependent: :destroy

    embeds_one :get_translation,                     class_name: 'Order::GetTranslation'
    embeds_one :get_original,                        class_name: 'Order::GetOriginal'
    embeds_one :events_manager,                      class_name: 'Order::Written::EventsManager', cascade_callbacks: true

    embeds_many :work_reports,                       class_name: 'Order::Written::WorkReport', cascade_callbacks: true
    accepts_nested_attributes_for :get_original, :get_translation, :work_reports, :attachments

    scope :all_orders,  -> (profile) { default_scope_for(profile).all }
    scope :open,        -> (profile) { default_scope_for(profile).where state: :wait_offer }
    scope :paying,      -> (profile) { profile.orders.where :state.in => [:new, :paying] }
    scope :in_progress, -> (profile) do
      default_scope_for(profile).where :state.in => [:in_progress, :additional_paying],
                                       connected_method_for(profile) => profile
    end
    scope :correct, ->(profile) {default_scope_for(profile).where state: :correcting}
    scope :control, ->(profile) {default_scope_for(profile).where state: :quality_control}
    scope :done, ->(profile) {default_scope_for(profile).where state: :sent_to_client}
    scope :close,       -> (profile) do
      default_scope_for(profile).where :state.in => [:close, :rated], connected_method_for(profile) => profile
    end

    validates_presence_of :original_language, :translation_language, :order_subtype, if: ->{step > 0}
    validates_presence_of :translation_type, :quantity_for_translate, if: ->{step > 0 && order_type.type_name == 'text'}
    validates_presence_of :quantity_for_translate, if: ->{step > 0 && order_type.type_name == 'document'}
    validate :attachments_count, if: ->{step > 1}

    # after_validation :change_state_event

    def attachments_count
      errors.add(attachments: 'expect at least one') if attachments.count == 0
    end

    # def change_state_event
    #   if state_event == 'waiting_correcting'
    #     Order::Written::EventsService.new(order).after_translate_order
    #   end
    # end

    state_machine initial: :new do
      state :correcting
      state :quality_control
      state :sent_to_client
      state :wait_corrector

      event :control do
        transition [:in_progress, :correcting] => :quality_control
      end

      event :waiting_correcting do
        transition in_progress: :wait_corrector
      end

      event :correct do
        transition [:in_progress, :wait_corrector] => :correcting
      end

      event :finish do
        transition quality_control: :sent_to_client
      end

      before_transition on: :correct do |order|
        order.notify_about_correct
      end

      before_transition on: :waiting_correcting do |order|
        OrderWrittenCorrectorQueueFactoryWorker.new.perform order.id, I18n.locale
        true
      end

      # before_transition on: :waiting_correcting do |order|
      #   Order::Written::EventsService.new(order).after_translate_order
      # end

      # after_transition any => :waiting_correcting do |order, transition|
      #   order.correct
      #   # Order::Written::EventsService.new(order).after_translate_order
      # end

      before_transition on: :control do |order|
        # unless order.translation_type == 'translate_and_correct'
        #   Order::Written::EventsService.new(order).after_translate_order
        # else
        #   Order::Written::EventsService.new(order).after_proof_reading
        # end
        order.notify_about_control
      end

      before_transition on: :finish do |order|
        order.notify_about_finish
        if order.get_translation.email.present?
          OrdersMailer.send_translation(order).deliver
        end
      end

      before_transition on: :process do |order|
        if order.assignee.present?
          order.notify_about_processing
        end
      end

      before_transition on: :paid do |order|
        Order::Written::EventsService.new(order).after_paid_order
        order.update paid_time: Time.now
      end

    end

    def self.available_for(profile)
      if profile.is_a? Profile::Translator
        query = []
        profile.services.where(written_approves: true).each do |s|
          if /From/.match(s.written_translate_type)
            query << {translation_language_id: s.language.id}
          end
          if /To|to/.match(s.written_translate_type)
            query << {original_language_id: s.language.id}
          end
        end
        Order::Written.any_of query
      end
    end

    def self.surcharge_for_postage(currency = nil)
      default = 30
      if currency
        Currency.exchange(default, currency).to_f
      else
        default
      end
    end

    def need_proof_reading?
      translation_type == 'translate_and_correct'
    end

    def original_price(currency = nil)
      if real_translation_language.nil?
        return 0
      else

        post_surcharge = 0
        if get_original.send_type == 'post'
          post_surcharge = Order::Written.surcharge_for_postage(currency)
        end

        (translation_type == 'translate_and_correct' ? price_correct : price_translate) + post_surcharge
      end
    end

    def price_translate(currency = nil)
      real_translation_language.nil? ? 0 : lang_price(real_translation_language, currency)
    end

    def price_correct(currency = nil)
      real_translation_language.nil? ? 0 : lang_price(real_translation_language, currency) * Price.get_increase_percent(real_translation_language, level)
    end

    def price_translate_currency(currency = nil)
      Currency.exchange_to_f price_translate, currency
    end

    def price_correct_currency(currency = nil)
      Currency.exchange_to_f price_correct, currency
    end

    def count_on_words?
      order_type.type_name == 'text'
    end

    def lang_price(lang, currency = nil)
      count = (quantity_for_translate || 0)
      if count_on_words?
        if count > border_quantity_for_translate
          base_price = base_lang_cost(lang) * count
        else
          if count > 0
            base_price = base_lang_cost(lang) * border_quantity_for_translate
          else
            base_price = 0
          end
        end
      else
        base_price = base_lang_cost(lang) * count
      end
      base_price
    end

    def quantity_for_translate
      read_attribute(:quantity_for_translate) || 0
    end

    def days_for_translate
      days_for_work('translate')
    end

    def days_for_translate_and_correct
      days_for_work('translate_and_correct')
    end

    def days_for_work(type = nil)
      translate_type = type || translation_type
      if order_type.type_name == 'document'
        return (quantity_for_translate / DOCS_PER_DAY).ceil
      else
        if order_type.type_name == 'text'
          days =  original_language.is_hieroglyph ? (quantity_for_translate / CHARS_PER_DAY_TRANS).ceil : (quantity_for_translate / WORDS_PER_DAY_TRANS).ceil
          if translate_type == 'translate_and_correct'
            days +=  original_language.is_hieroglyph ? (quantity_for_translate / CHARS_PER_DAY_PROOF).ceil : (quantity_for_translate / WORDS_PER_DAY_PROOF).ceil
          end
          return days
        end
      end
    end

    def border_quantity_for_translate
      original_language.is_hieroglyph ? 800 : 500
    end

    def senior
      real_translation_language.try :senior
    end

    def close_cash_flow
      price_to_members = self.price * 0.95
      if translation_type == 'translate'
        # self.create_and_execute_transaction Office.head, assignee.user, price_to_members*0.7
        self.create_and_execute_transaction Office.head, real_translation_language.senior.user, price_to_members*0.03
      else
        # self.create_and_execute_transaction Office.head, assignee.user, price_to_members*0.7*0.7
        self.create_and_execute_transaction Office.head, real_translation_language.senior.user, price_to_members*0.7*0.3
        self.create_and_execute_transaction Office.head, real_translation_language.senior.user, price_to_members*0.03
      end
    end

    def primary_supported_translators
      []
    end

    def secondary_supported_translators
      []
    end

    def real_translation_language
      return translation_language unless translation_language.nil? || translation_language.try(:is_chinese)
      return original_language unless original_language.nil? || original_language.try(:is_chinese)
      return nil
    end

    def base_lang_cost(lang)
      group = lang.languages_group
      value_name = original_language.is_hieroglyph && count_on_words? ? :value_ch : :value
      group.written_prices.find_by(written_type_id: order_type.id).send(value_name) || 0
    end

    def paying_items
      res = []
      res << {cost: price_translate, description: I18n.t('order.writt.translate')}
      if translation_type == 'translate_and_correct'
        res << {cost: price_correct - price_translate, description: I18n.t('order.writt.correct')}
      end

      if get_original.send_type == 'post'
        res << {cost: Order::Written.surcharge_for_postage, description: I18n.t('order.writt.postage')}
      end
        res
    end

    private
    def build_relations
      build_get_original
      build_get_translation
    end
  end
end