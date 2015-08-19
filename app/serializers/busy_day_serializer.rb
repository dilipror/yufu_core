class BusyDaySerializer < ActiveModel::Serializer
  attributes :id, :date, :is_hold
end