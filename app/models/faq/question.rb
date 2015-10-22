module Faq
  class Question
    include Mongoid::Document

    field :text

    has_one :answer, class_name: 'Faq::Answer'

    belongs_to :category, class_name: 'Faq::Category'
    belongs_to :user

    validates_presence_of :text

  end
end