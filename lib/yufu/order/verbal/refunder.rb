module Order
  class Order
    class Refunder
      def initialize(order)
        @order = order
      end

      def refund

      end

      def calculate_sum
        full_cost = order.invoice.last.cost

      end

      private

      def full_with_cover(cost)
        cost + 192
      end

      def full(cost) cost end

      def minus_one_day(cost)
        cost - @order.language.verbal_price(@order.level) * 8
      end

      def half(cost)
        one_day_cost = @order.language.verbal_price(@order.level) * 8
        half = cost / 2
        half >= one_day_cost ? half : one_day_cost
      end

      def sector_zero
        0
      end

    end
  end
end