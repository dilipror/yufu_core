module Profile
  module Steps
    class LanguageMain
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :native_language,  class_name: 'Language'
      belongs_to :citizenship,      class_name: 'Country'
      belongs_to :profile_language, class_name: 'Language'

      embedded_in :translator

      validates_presence_of :native_language, :citizenship, :profile_language, if: :persisted?
      before_save :build_default_service,
                  if: -> {native_language.present? && !native_language.is_chinese? && translator.services.empty?}

      def build_default_service
        translator.services.build language: native_language
        true
      end

    end
  end
end