module Order
  class Written < Base
    include Mongoid::Paperclip

    before_create :build_relations

    TYPES  = %w(text document media)
    LEVELS = %w(translate_and_correct translate)

    field :translation_type
    field :quantity_for_translate, type: Integer, default: 0
    field :level
    field :second_level

    has_mongoid_attached_file :translation
    do_not_validate_attachment_file_type :translation

    has_notification_about :correct, observers: ->(order){[order.owner, order.senior]}, message: 'notifications.correcting_order'
    has_notification_about :control, observers: ->(order){[order.owner, order.senior]}, message: 'notifications.control_order'
    has_notification_about :finish, observers: :owner, message: 'notifications.done_order'

    belongs_to :original_language,                   class_name: 'Language'
    belongs_to :translation_language,                class_name: 'Language'
    belongs_to :order_type,                          class_name: 'Order::Written::WrittenType'
    belongs_to :order_subtype,                       class_name: 'Order::Written::WrittenSubtype'

    has_and_belongs_to_many :available_languages,    class_name: 'Language'
    has_and_belongs_to_many :attachments, dependent: :destroy

    embeds_one :get_translation,                     class_name: 'Order::GetTranslation'
    embeds_one :get_original,                        class_name: 'Order::GetOriginal'
    embeds_many :work_reports,                       class_name: 'Order::Written::WorkReport', cascade_callbacks: true
    accepts_nested_attributes_for :get_original, :get_translation, :work_reports, :attachments

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

    def attachments_count
      errors.add(attachments: 'expect at least one') if attachments.count == 0
    end

    def senior
      real_translation_language.senior
    end

    # def lang_price()
    #
    # def cost(currency = nil, curr_level = level)
    #   (translation_languages.inject(0) {|sum, l| sum + l.written_cost(curr_level, currency) * words_number})
    # end
    #
    # def price(currency = nil, curr_level = level)
    #   if translation_type == 'translate' or translation_type.nil?
    #     return Price.with_markup(cost currency, curr_level)
    #   end
    #   if translation_type == 'translate_and_correct'
    #     Price.with_markup(cost currency, curr_level) * (1 + Price.get_increase_percent(translation_languages.first, level) / 100)
    #   end
    # end

    #  test--------------------------------------------------------------


    state_machine initial: :new do
      state :correcting
      state :quality_control
      state :sent_to_client

      event :control do
        transition [:in_progress, :correcting] => :quality_control
      end

      event :correct do
        transition in_progress: :correcting
      end

      event :finish do
        transition quality_control: :sent_to_client
      end

      before_transition on: :correct do |order|
        order.notify_about_correct
      end

      before_transition on: :control do |order|
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

    # def cost(currency = nil)
    #   Price.without_markup price currency
    # end


    def original_price(currency = nil)
      if real_translation_language.nil?
        return 0
      else
        translation_type == 'translate_and_correct' ? price_correct : price_translate
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

    def border_quantity_for_translate
      original_language.is_chinese ? 800 : 500
    end

    def close_cash_flow
      price_to_members = self.price * 0.95
      if translation_type == 'translate'
        self.create_and_execute_transaction Office.head, assignee.user, price_to_members*0.7
        self.create_and_execute_transaction Office.head, real_translation_language.senior.user, price_to_members*0.03
      else
        self.create_and_execute_transaction Office.head, assignee.user, price_to_members*0.7*0.7
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
      value_name = original_language.is_chinese && count_on_words? ? :value_ch : :value
      group.written_prices.find_by(written_type_id: order_type.id).send value_name
    end

    def paying_items
      res = []
      res << {cost: price_translate, description: I18n.t('order.written.translate')}
      if translation_type == 'translate_and_correct'
        res << {cost: price_correct - price_translate, description: I18n.t('order.written.correct')}
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