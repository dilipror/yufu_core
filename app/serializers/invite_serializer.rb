class InviteSerializer < ActiveModel::Serializer
  attributes :id, :email, :last_name, :first_name, :middle_name, :overlord_id, :vassal_id,
             :invitation_text_id, :pass_registration?, :expired

  # has_one :invitation_text

  def invitation_text_id
    @object.invitation_text.id if @object.invitation_text.present?
  end

  def vassal_id
    @object.vassal.id if @object.vassal.present?
  end

end
