module Profile
  class Education
    include Mongoid::Document
    extend Enumerize

    field :grade
    field :university
    field :is_approved,    type: Mongoid::Boolean

    belongs_to :major
    belongs_to :country

    embedded_in :profile_translator
    embeds_many :documents, class_name: 'Profile::Document', :cascade_callbacks => true
    accepts_nested_attributes_for :documents

    validates_presence_of :grade, :university, :major, :country

    enumerize :grade, in: ['bachelor', 'master', 'mba', 'phd', 'other']

    def name
      university
    end

    def owner?(user)
     return false if _parent.translator.nil?
     user == _parent.translator.user
    end

  end
end