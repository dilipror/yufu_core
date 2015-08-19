class Profile::EducationSerializer < ActiveModel::Serializer
  attributes :id, :grade, :university, :major_id, :country_id
  has_many :documents
end
