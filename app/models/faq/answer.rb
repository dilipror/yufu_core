module Faq
  class Answer
    include Mongoid::Document

    field :text, localize: true

    belongs_to :question, class_name: 'Faq::Question'

    validates_presence_of :text

  end
end