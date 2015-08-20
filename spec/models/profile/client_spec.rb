require 'rails_helper'

RSpec.describe Profile::Client, :type => :model do

  describe 'validate if' do

    let(:client){build :profile_client, attrs}

    subject{client.valid?}


    context 'valid' do

      let(:attrs) {{company_name: nil, company_address: nil, company_uid: nil}}

      it{is_expected.to be_truthy}

    end

    context 'invalid' do

      let(:attrs) {{company_name: 'Swasilend', company_address: nil, company_uid: nil}}

      it{is_expected.to be false}

    end

  end

end