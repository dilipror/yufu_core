module Order
  class ServiceOrder
      include Mongoid::Document

      field :count, default: 1, type: Integer
      #fields for custom service
      field :support_custom, type: Boolean, default: false
      field :description

      belongs_to :service, class_name: 'Order::Service'

      embedded_in :order_local_experts, :class_name => 'Order::LocalExpert'

      def cost
        if order_local_experts.services_pack.need_downpayments
          service.downpayments || 0
        else
          service.cost + (count - 1) * service.cost * (100 - service.discount) / 100
        end
      rescue
        return 0
      end
  end
end