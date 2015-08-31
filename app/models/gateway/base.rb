module Gateway
  class Base
    include Mongoid::Document

    has_and_belongs_to_many :taxes

    def afterCreatePayment

    end

    def afterPaidPayment

    end
    
  end
end