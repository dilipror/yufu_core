class BusyDay
  include Mongoid::Document

  field :date, type: Date

  embedded_in :profile_translator
  belongs_to :order_verbal, class_name: 'Order::Verbal'

  validates_presence_of :date, uniqueness: true

  def hold?
    order_verbal.present?
  end
  alias :is_hold :hold?
end
