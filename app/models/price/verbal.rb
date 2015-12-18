module Price
  class Verbal < Base
    validates :level, presence: true, inclusion: Order::Verbal::TRANSLATION_LEVELS.keys.map(&:to_s)
  end
end
