module Profile
  module Steps
    class Education
      include Mongoid::Document
      include Mongoid::Timestamps

      field :is_updated, type: Mongoid::Boolean, default: false

      embeds_many :educations, class_name: 'Profile::Education', cascade_callbacks: true

      accepts_nested_attributes_for :educations, allow_destroy: true

      embedded_in :translator

    end
  end
end