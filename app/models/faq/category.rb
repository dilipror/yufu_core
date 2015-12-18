module Faq
  class Category
    include Mongoid::Document
    include BlankLocalizedFields

    field :position, type: Integer
    field :name, localize: true

    has_many :questions, class_name: 'Faq::Question', dependent: :destroy

    validates_presence_of :name

    default_scope -> {asc :position}

    clear_localized :name

  end
end