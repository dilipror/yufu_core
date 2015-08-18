module Order
  module RequiredData
    class Base
      include Mongoid::Document

      embedded_in :order, class_name: 'Order::LocalExpert'
    end
  end
end