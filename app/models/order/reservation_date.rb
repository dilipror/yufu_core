module Order
  class ReservationDate
    include Mongoid::Document
    include Priced

    field :date,  type: Date
    field :hours, type: Integer, default: 8
    field :is_confirmed, type: Mongoid::Boolean
    # belongs_to :order_language_criterion, class_name: 'Order::LanguageCriterion'
    embedded_in :order_verbal, class_name: 'Order::Verbal'

    validates_presence_of    :date
    validates_uniqueness_of  :date, scope: [:order_verbal]

    delegate :language, :level, to: :order_verbal, allow_nil: true
    delegate :location, to: :order_verbal

    scope :confirmed, -> { where is_confirmed: true }

    def available?(language = nil, city = nil, level = nil)
      language = language || order_verbal.try(:language)
      city     = city     || order_verbal.location
      level    = level    || order_verbal.try(:level)
      !Profile::Translator.free_on(date).support_services(language, city, level).empty?
    end
    alias :available_for? :available?

    # Deprecated
    def available_level(language = nil, city = nil)
      return level if available?(language)
      Order::Verbal::TRANSLATION_LEVELS.reverse.each do |lvl|
        return lvl if available?(language, city, lvl)
      end
      return nil
    end

    def simple_price_for_hours(hours = nil)
      hours ||= self.hours
      return 0 unless is_confirmed
      return 0 if order_verbal.language.nil? || order_verbal.level.nil?
      day_cost = order_verbal.language.verbal_price(level)
      day_cost * hours
    end

    def original_price_without_overtime
      price = simple_price_for_hours
      hours < 8 ? price * 1.5 : price
    end

    def overtime_price
      return 0 if hours <= 8
      hour_cost = order_verbal.language.verbal_price(level)
      return (hours - 8) * hour_cost * 0.5 if hours > 8
    end

    def original_price
      return 0 unless is_confirmed
      return 0 if order_verbal.language.nil? || order_verbal.level.nil?
      hour_cost = order_verbal.language.verbal_price(level)
      price = hour_cost * hours
      price += overtime_price if hours > 8
      price =  hours * hour_cost * 1.5 if hours < 8
      price
    end
  end
end
