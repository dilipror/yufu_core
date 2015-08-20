class Translation
  include Mongoid::Document

  field :key
  field :value

  belongs_to :version, class_name: 'Localization::Version'
end