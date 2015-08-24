class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :pay_company, :cost, :state, :subject_id, :number, :description, :subject_type
  #TODO:  Временно выпилил subject_type, так как на фронте связь не полиморфная.
  # Надо решить эту проблему.
  #
  # временно вернул subject_type, так как его отсутствие ломает инвойс к ебеням
  has_many :items
  has_one :pay_way

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
