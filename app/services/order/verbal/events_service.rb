module Order
  class Verbal
    class EventsService
      def initialize(order)
        @order = order
      end

      def after_12
        if @order.offers.count == 0
          Support::Ticket.create assigned_to: @order.main_language_criterion.language, order: self,
                                 theme: Support::Theme.where(type: 'no_translator_found').first, subject: I18n.t('tickets.subjects.no_translator_found')
        end
      end

      def after_24
        if @order.offers.count == 0
          @order.notify_about_looking_for_int
        end
      end

      def before_60
        if @order.primary_offer.present?
          @order.notify_about_check_dates
          @order.primary_offer.notify_about_re_confirm_main if @order.primary_offer.present?
        end
      end

      def before_48
        @order.secondary_offer.notify_about_re_confirm_back_up if @order.secondary_offer.present?
      end

      def before_36
        if @order.wait_offer?
          Support::Ticket.create! assigned_to: @order.main_language_criterion.language.senior.try(:user), order: @order,
                                  theme: Support::Theme.where(type: 'no_offers_confirmed').first, subject: I18n.t('tickets.subjects.no_offers_confirmed')
        end
      end

      def before_24
        if @order.wait_offer?
          @order.notify_about_looking_for_int_before_24
        end
      end

      def before_4
        if @order.wait_offer?
          @order.notify_about_cancel
          RejectService.new(@order).reject_order :yufu
        end
      end

    end
  end
end