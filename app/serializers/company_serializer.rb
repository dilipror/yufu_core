class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name, :tooltip, :support_copy_invoice, :currency_code

  def currency_code
    @object.currency.iso_code
  end
end
