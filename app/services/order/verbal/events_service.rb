module Order
  class Verbal
    class EventsService
      def initialize(order)
        @order = order
      end

      def after_12
        if @order.confirmation_delay
          Support::Ticket.create assigned_to: @order.main_language_criterion.language, order: self,
                               theme: Support::Theme.where(type: 'no_translator_found').first, subject: I18n.t('tickets.subjects.no_translator_found')
        end
      end

      def after_24
        if @order.translator_not_found
          @order.notify_about_we_are_looking_10
        end
      end

      def before_60
        @order.notify_about_check_dates_5
        @order.primary_offer.notify_about_re_confirm_main_19 if @order.to_reconfirm
      end

      def before_48
        if @order.main_reconfirm_delay
          @order.secondary_offer.notify_about_re_confirm_back_up_20 if @order.secondary_offer.present?
        end
      end

      def before_36
        if @order.reconfirm_delay
          Support::Ticket.create! assigned_to: @order.main_language_criterion.language.senior.try(:user), order: @order,
                                  theme: Support::Theme.where(type: 'no_offers_confirmed').first, subject: I18n.t('tickets.subjects.no_offers_confirmed')
        end
      end

      def before_24
        if @order.reconfirm_delay?
          @order.notify_about_we_are_looking_before_24_11
        end
      end

      def before_4
        if @order.cancel_by_yufu
          @order.notify_about_cancel_12
          RejectService.new(@order).reject_order :yufu
        end
      end

    end
  end
end