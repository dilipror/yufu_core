class Direction
  include Mongoid::Document

  LEVELS = %w(norm nenorm)

  field :name, localize: true

  validates_presence_of :name, uniqueness: true
end
