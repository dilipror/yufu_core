class WithdrawalSerializer < ActiveModel::Serializer
  attributes :id, :sum, :state, :human_state_name
end