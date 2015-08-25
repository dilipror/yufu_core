module Profile
  module Steps
    class Personal
      include Mongoid::Document
      include Mongoid::Timestamps
      extend Enumerize

      field :years_out_of_china, type: Integer

      belongs_to :status, class_name: 'Profile::Ocupation'

      delegate :first_name, :first_name=, :last_name, :last_name=, :birthday, :birthday=, :name_in_pinyin, :name_in_pinyin=,
               :identification_number, :identification_number=, :sex, :sex=, :avatar, :avatar=, :surname_in_pinyin, :surname_in_pinyin=,
               :avatar_file_size, :avatar_file_size=, :avatar_file_name, :avatar_file_name=,
               :avatar_content_type, :avatar_content_type=, to: :translator, allow_nil: true

      embedded_in :translator

      validates_presence_of :first_name, :last_name, :birthday, :identification_number, :sex, :status, :years_out_of_china,
                            if: :persisted?
      validates_presence_of :name_in_pinyin, :surname_in_pinyin, if: :needs_pinyin?

      after_save do
        # translator.user.password = translator.user.password_confirmation = nil
        translator.user.save!
      end


      def needs_pinyin?
        persisted? && translator.profile_steps_language.try(:native_language).try(:is_chinese)
      end

    end
  end
end