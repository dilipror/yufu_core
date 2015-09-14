class Profile::ServiceSerializer < ActiveModel::Serializer
  attributes :id, :level, :verbal_price, :written_price, :written_translate_type, :language_id, :corrector,
             :additions, :claim_senior, :written_approves, :is_approved, :local_expert, :only_written,
             :translator_id, :is_senior

  has_one :level_up_request

  def translator_id
    @object.translator.id
  end

end
