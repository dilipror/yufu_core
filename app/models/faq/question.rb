module Faq
  class Question
    include Mongoid::Document
    include BlankLocalizedFields

    field :position, type: Integer
    field :text, localize: true

    has_one :answer, class_name: 'Faq::Answer', dependent: :destroy

    belongs_to :category, class_name: 'Faq::Category'

    validates_presence_of :text

    default_scope -> {asc :position}

    clear_localized :text

    def name
      text
    end
  end
end