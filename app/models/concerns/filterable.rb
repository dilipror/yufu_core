module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter(filtering_params)
      results = self
      filtering_params.each do |key, value|
        results = results.public_send(key, value) if value.present?# && self.respond_to?(key.to_sym)
      end
      results
      # return results unless results == self
      # nil
    end
    # def filter(filtering_params)
    #   results = nil
    #   str = "#{self}"
    #   filtering_params.each do |key, value|
    #     str += ".#{key}(#{value})" if value.present?
    #     # tmp = self
    #     # results = results.public_send(key, value) if value.present?# && self.respond_to?(key.to_sym)
    #   end
    #   return eval(str) unless results == self
    #   nil
    # end
  end
end