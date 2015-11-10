module Profile
  module Steps
    class Service
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hsk_level, type: Integer
      field :is_updated, type: Mongoid::Boolean, default: false
      field :chinese_description

      has_and_belongs_to_many :cities,                class_name: 'City'
      has_and_belongs_to_many :cities_with_surcharge, class_name: 'City'
      has_and_belongs_to_many :directions

      embedded_in :translator

      delegate :services, :services=, to: :translator

      validates :services, length: {minimum: 1}
      validates :city_ids, length: {minimum: 1}

      after_save :hard_resolve_city

      after_save :change_translator_state, if: -> {(city_ids_changed?) &&
                                             translator.try(:state) == 'approved'}

      def change_translator_state
        translator.approving if translator.present? && translator.can_approving?
      end

      def hard_resolve_city
        if translator.persisted?
          cities.each do |city|
            translator.city_approves.create city: city unless translator.city_approves.where(city: city).count > 0
          end
          cities_with_surcharge.each do |city|
            translator.city_approves.create city: city, with_surcharge: true unless translator.city_approves.where(city: city).count > 0
          end
          translator.city_approves.with_surcharge.each do |ca|
            ca.destroy unless cities_with_surcharge.include? ca.city
          end
          translator.city_approves.without_surcharge.each do |ca|
            ca.destroy unless cities.include? ca.city
          end
        end
      end

      private
      def create_approve(city)
        translator.city_approves.create city: city
      end

      def remove_approve(city)
        translator.city_approves.where(city: city).destroy_all
      end
    end
  end
end