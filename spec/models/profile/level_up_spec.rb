require 'rails_helper'

RSpec.describe Profile::LevelUpRequest, type: 'model' do

  describe '#check_level_up' do

    let(:service) {create :service, level: 1}

    subject{lvl_up.check_level_up}

    context 'when approved lvlup' do
      let(:lvl_up) {create :level_up_request, from: 1, to: 2, service: service,
                           state: :approved}
      it{expect{subject}.to change{service.level}.from(1).to(2)}

    end

    context 'when rejected lvlup' do
      let(:lvl_up) {create :level_up_request, from: 1, to: 2, service: service,
                           state: :rejected}
      it{expect{subject}.not_to change{service.level}}
    end
  end
end