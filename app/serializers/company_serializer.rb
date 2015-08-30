class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name, :tooltip, :support_copy_invoice
end
