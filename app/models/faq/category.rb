module Faq
  class Category
    include Mongoid::Document

    field :name

    has_many :questions, class_name: 'Faq::Question'

    validates_presence_of :name

  end
end