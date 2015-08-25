module Price
  class Base
    include Mongoid::Document
    field :value,     type: BigDecimal
    field :value_ch,  type: BigDecimal
    field :level,  type: String

    embedded_in :languages_group

    validates :level, presence: true

    def name
      "Level - #{level}"
    end
  end
end
