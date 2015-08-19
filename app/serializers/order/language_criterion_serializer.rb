class Order::LanguageCriterionSerializer < ActiveModel::Serializer
  attributes :id, :level, :cost, :language_id
end
