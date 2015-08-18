class Group
  include Mongoid::Document

  field :name

  has_and_belongs_to_many :users

  embeds_many :permissions
  accepts_nested_attributes_for :permissions

end