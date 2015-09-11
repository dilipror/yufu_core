# DEPRECATED
class Localization::VersionNumber
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  has_many :localization_versions, class_name: 'Localization::Version', dependent: :destroy

  auto_increment :number

  after_create do
    Localization::Version.create localization: Localization.default, version_number: self
  end
end
