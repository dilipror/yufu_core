module Faq
  class Category
    include Mongoid::Document
    include BlankLocalizedFields

    field :name, localize: true

    has_many :questions, class_name: 'Faq::Question', dependent: :destroy

    validates_presence_of :name

  end
end