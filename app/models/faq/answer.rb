module Faq
  class Answer
    include Mongoid::Document

    field :text

    belongs_to :question, class_name: 'Faq::Question'

    validates_presence_of :text

  end
end