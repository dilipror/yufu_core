module Faq
  class Answer
    include Mongoid::Document
    include BlankLocalizedFields

    field :text, localize: true

    belongs_to :question, class_name: 'Faq::Question'

    validates_presence_of :text, :question

    clear_localized :text

  end
end