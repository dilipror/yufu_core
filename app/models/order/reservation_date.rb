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

    def original_price_without_overtime
      price =  order_verbal.language.verbal_price(level) * hours
      hours < 8 ? price * 1.5 : price
    end

    def overtime_price(is_first_date: false, work_start_at: nil)
      hour_cost = order_verbal.language.verbal_price(level)

      standard_overtime = hours > 8 ? (hours - 8) * hour_cost * 0.5 : 0

      if is_first_date && work_start_at.is_a?(Integer)
        before_overtime = [[(7 - work_start_at), 0].max, hours].min
        after_over_time = [(work_start_at + hours - 21), 0].max
        standard_overtime + (before_overtime + after_over_time) * hour_cost * 0.5
      else
        standard_overtime
      end
    end

    def original_price(is_first_date: false, work_start_at: nil)
      return 0 unless is_confirmed
      return 0 if order_verbal.language.nil? || order_verbal.level.nil?
      original_price_without_overtime + overtime_price(is_first_date: is_first_date, work_start_at: work_start_at)
    end
  end
end
