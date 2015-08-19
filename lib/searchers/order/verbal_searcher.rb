module Searchers
  module Order
    class VerbalSearcher

      def initialize(profile)
        @profile = profile
      end

      def search
        order_ids = @profile.order_verbal_translators_queues.active.distinct(:order_verbal_id)
        ::Order::Verbal.wait_offer.where :id.in => order_ids
      end
    end
  end
end