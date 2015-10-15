module Order
  class Written
    class EventsService
      def initialize(order)
        @order = order
      end

      def after_paid_order
        OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale
      end

      def after_translate_order
        if @order.translation_language.is_chinese
          if @order.assignee.chinese?
            if @order.need_proof_reading?
              Support::Ticket.create text: I18n.t('frontend.order.writt.default_text_for_ticket'),
                                     theme: Support::Theme.for_order_written.first,
                                     subject: I18n.t('frontend.order.writt.default_subject_for_ticket'),
                                     order: @order
              @order.state_event = 'correct'
            else
              @order.state_event = 'control'
            end
          else#обязательно пруф ридинг тк переводил не китаец
            Support::Ticket.create text: I18n.t('frontend.order.writt.default_text_for_ticket'),
                                   theme: Support::Theme.for_order_written.first,
                                   subject: I18n.t('frontend.order.writt.default_subject_for_ticket'),
                                   order: @order
            @order.state_event = 'correct'
          end
        else# from ch to any
          if @order.need_proof_reading?
            if @order.assignee.can_proof_read? @order.translation_language
              @order.state_event = 'correct'
              @order.proof_reader = @order.assignee
            else
              @order.state_event = 'waiting_correcting'
            end
          else
            @order.state_event = 'control'
          end
        end


      end

      def confirmation_order_in_30
        if @order.assignee.present?
          # wait translation
        else
          if (Profile::Translator.approved.support_written_order(@order).where(:'profile_steps_service.hsk_level'.gt => 4)).count > 0
            OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale
          else
            @order.notify_about_cancellation_by_yufu
          end
        end

      end
    end
  end
end
