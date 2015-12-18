module Support
  class Theme
    include Mongoid::Document
    include Mongoid::Autoinc
    extend Enumerize

    field :name, localize: true
    field :number, type: Integer
    field :theme_type, default: :custom

    increments :number

    enumerize :type, in: [:custom, :local_expert, :no_translator_found, :no_offers_confirmed]
    enumerize :theme_type, in: [:custom, :local_expert, :order_written]
    scope :custom,           -> {where theme_type: :custom}
    scope :for_local_expert, -> {where theme_type: :local_expert}
    scope :for_order_written, -> {where theme_type: :order_written}


    validates :name, presence: true, uniqueness: true

  end
end
