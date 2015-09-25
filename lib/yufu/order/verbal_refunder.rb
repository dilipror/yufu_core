module Order
  class VerbalRefunder
    def initialize(order)
      @order = order
    end

    def refund(cancel_by: :client)

    end

    def calculate_sum(cancel_by)
      if cancel_by == :yufu
        return full_with_cover if @order.will_begin_less_than?(4.hour)
        return full if (@order.paying? || @order.new?) && !@order.paid_less_then?(7.days)
      else
        return full if @order.paid_less_then?(24.hours)
        if @order.has_offer?
          if @order.in_progress?
            return sector_zero
          else
            return minus_one_day unless will_begin_less_than? 14.days
            if @order.will_begin_less_than? 7.days
              return sector_zero
            else
              return half
            end
          end
        else
          return @order.paid_less_then?(24.hours) ? full : full_with_cover
        end

      end
    end

    private

    def cost
      @order.invoces.first.cost
    end

    def full_with_cover
      cost + 192
    end

    def full; cost end

    def minus_one_day
      cost - @order.language.verbal_price(@order.level) * 8
    end

    def half
      one_day_cost = @order.language.verbal_price(@order.level) * 8
      half = cost / 2
      half >= one_day_cost ? half : one_day_cost
    end

    def sector_zero
      0
    end

end
end