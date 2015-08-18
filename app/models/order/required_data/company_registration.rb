module Order
  module RequiredData
    class CompanyRegistration < Base
      field :registrations_place
      field :communications_language
      field :documentation_language
      field :power_of_attorney, type: Boolean

      delegate :owner, to: :order

      belongs_to :communications_language, class_name: 'Language'
      belongs_to :documentation_language,  class_name: 'Language'
    end
  end
end