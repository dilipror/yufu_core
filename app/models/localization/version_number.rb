class Localization::VersionNumber
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  auto_increment :number

  after_create do
    Localization::Version.create localization: Localization.default, version_number: self
  end
end
