module Faq
  class Question
    include Mongoid::Document
    include BlankLocalizedFields

    field :text, localize: true

    has_one :answer, class_name: 'Faq::Answer', dependent: :destroy

    belongs_to :category, class_name: 'Faq::Category'

    validates_presence_of :text

  end
end