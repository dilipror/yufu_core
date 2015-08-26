module Profile
  class Ocupation
    include Mongoid::Document

    field :name, localize: true

  end
end