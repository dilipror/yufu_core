module PromoObject
  extend ActiveSupport::Concern

  included do
    embeds_many :visits, as: :visitable
    has_many :order_bases, :class_name => 'Order::Base', dependent: :nullify

    accepts_nested_attributes_for :visits
  end
end