class Statistic
  TYPES = [:invites, :banners, :link]
  attr_accessor :id, :collector

  delegate :count, :clicked_count, :clicked_percent, :commission, :pass_registration_count, :pass_registration_percent,
           :orders_count, :orders_count_percent, to: :collector

  def initialize(user, type)
    raise ArgumentError if !user.is_a?(User) || !TYPES.include?(type.to_sym)
    @id = type
    @collector = "Statistic::#{type.capitalize}".constantize.new(user)
  end

  def read_attribute_for_serialization(n)
    self.try n
  end
end