module Order
  class Hotel
    include Mongoid::Document
    include MultiParameterAttributes

    field :greeted_at, type: Time
    field :info
    field :have_not_yet_booked, type: Boolean

    embedded_in :order_base
  end

end
