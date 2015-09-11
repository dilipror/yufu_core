class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :cost, :state, :subject_id, :number, :description, :subject_type,
             :need_invoice_copy, :user_id, :company_name, :company_uid, :company_address
  #TODO:  Временно выпилил subject_type, так как на фронте связь не полиморфная.
  # Надо решить эту проблему.
  #
  # временно вернул subject_type, так как его отсутствие ломает инвойс к ебеням
  has_many :items
  has_one :pay_way
  has_one :pay_company

  def subject_type

    if @object.subject.nil?
      return ''
    end
    #костыль для ембера, что модель верно определялась
    if @object.subject._type.demodulize.downcase == 'Order::LocalExpert'
      return 'local-expert'
    end
    @object.subject._type.demodulize.downcase
  end

  def cost
    @object.exchanged_cost
  end

  has_one :client_info
end
