module Order
  class Verbal
    class RejectService < ::Order::RejectService

      def calculate_sum(cancel_by)
        if cancel_by == :yufu
          return full_with_cover if @order.will_begin_less_than?(4.hours)
          #return full if (@order.paying? || @order.new?) && !@order.paid_less_then?(7.days) ????
        else
          if @order.has_offer?
            if @order.in_progress?
              return sector_zero
            else
              return sector_zero if @order.will_begin_less_than? 7.days
              return half if  @order.will_begin_at? 7.days
              return minus_one_day if @order.will_begin_less_than? 14.days
            end
          else
            return @order.paid_ago?(24.hours) ? full_with_cover : full
          end
        end
        0
      end

      private

      def minus_one_day
        cost - @order.language.verbal_price(@order.level) * 8
      end

      def half
        one_day_cost = @order.language.verbal_price(@order.level) * 8
        half = cost / 2
        [(half >= one_day_cost ? half : cost - one_day_cost), 0].max
      end

    end
  end
end