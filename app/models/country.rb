class Country
  include Mongoid::Document

  field :name, localize: true
  field :is_china, type: Mongoid::Boolean, default: false
  field :is_EU, type: Boolean
  field :is_HongKong, type: Boolean

  scope :china, -> {where(is_china: true)}
  scope :eu, -> {where(is_EU: true)}

  has_and_belongs_to_many :taxes

  def self.hongKong
    where(is_HongKong: true).first
  end
end