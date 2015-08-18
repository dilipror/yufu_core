module Monetizeable
  extend ActiveSupport::Concern

  module ClassMethods
    def monetize(*fields)
      fields.each do |field|
        define_method "#{field}_money" do
          Money.new self.send(field)
        end

        define_method "exchanged_#{field}" do |to = nil|
          Currency.exchange(self.send(field), to).to_f
        end
      end
    end
  end
end