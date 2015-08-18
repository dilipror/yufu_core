class Province
  include Mongoid::Document
  field :name, localize: true

  has_many :cities

  validates :name, presence: true, uniqueness: true
end
