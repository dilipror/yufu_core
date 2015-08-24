module Gateway
  class Base
    include Mongoid::Document


    def afterCreatePayment

    end

    def afterPaidPayment

    end
    
  end
end