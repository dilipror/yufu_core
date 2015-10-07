module Order
  class Written
    class EventsService
      def initialize(order)
        @order = order
      end

      def after_proof_reading
        # 70 / 40 to proof reader
        # quality control
      end

      def after_translate_order
        if order.translation_language.is_chinese
          # 70% to trans
          if translation_type == 'translate_and_correct'
            # ticket
            # quality control
          else
            # quality control
          end
        else

        end
        # 70% to trans
        # ORDER CONFIRMED
        if translation_type == 'translate_and_correct'
          if order.proof_reader == order.assignee
          else
            # NEW ORDER AVAI
          end
        end

        end

      def confirmation_order_in_30
        if order.assignee.present?
          # wait translation
        else
          if (Profile::Translator.approved.where(:'profile_steps_service.hsk_level'.gt => 4)).count > 0
            # NEW ORDER AVAI
            # wait translation
          else
            # cancellation by yufu
          end
        end

      end
    end
  end
end
