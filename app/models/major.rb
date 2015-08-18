class Major
  include Mongoid::Document
  include BlankLocalizedFields

  field :name, localize: true

  validates :name, uniqueness: true, presence: true
  clear_localized :name
end
