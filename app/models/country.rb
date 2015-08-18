class Country
  include Mongoid::Document

  field :name, localize: true
  field :is_china, type: Mongoid::Boolean, default: false

  scope :china, -> {where(is_china: true)}
end