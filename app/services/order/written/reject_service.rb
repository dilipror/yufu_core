module Order
  class Written
    class RejectService < ::Order::RejectService
      def calculate_sum(cancel_by)
        if cancel_by == :yufu
          return full
        else
          if @order.in_progress?
            return sector_zero
          else
            return @order.paid_ago?(7.days) ? full_with_cover : full
          end
        end
      end


    end
  end
end