class LanguageSerializer < ActiveModel::Serializer
  attributes :id, :name, :short_name, :is_chinese, :is_for_profile, :support_written_correctors, :is_hieroglyph,
             :has_senior, :available_level_ids, :senior_id, :language_group

  def available_level_ids
    # @object.available_levels
    []
  end

  def language_group
	  @object.languages_group.name
  end
end
