module Order
  module Gateway
    class Base
      include Mongoid::Document
      belongs_to :payment, class_name: 'Order::Payment', polymorphic: true
    end
  end
end