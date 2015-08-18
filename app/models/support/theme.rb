module Support
  class Theme
    include Mongoid::Document
    include Mongoid::Autoinc
    extend Enumerize

    field :name, localize: true
    field :number, type: Integer
    field :type, default: :custom
    field :for_local_expert, type: Boolean, default: false

    increments :number

    enumerize :type, in: [:custom, :local_expert]
    #scope :custom,           -> {where type: :custom}
    #scope :for_local_expert, -> {where type: :local_expert}


    validates :name, presence: true, uniqueness: true

  end
end
