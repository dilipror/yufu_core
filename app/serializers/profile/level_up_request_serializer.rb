class Profile::LevelUpRequestSerializer < ActiveModel::Serializer
  attributes :id, :from, :to, :service_id, :under_consideration
end
