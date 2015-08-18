require 'rails_helper'

RSpec.describe Profile::Steps::Service do

  describe 'habtm callbacks' do
    let(:translator) {create :profile_translator, city_approves: []}
    let(:step_service) {translator.profile_steps_service}
    let(:city) {create :city}
    let(:city2) {create :city}

    before(:each){translator}

    describe 'add city' do
      subject{step_service.update city_ids: [city.id]}

      it {expect{subject}.to change{CityApprove.count}.by(1)}
    end

    describe 'remove city' do
      before(:each) {step_service.update! city_ids: [city.id, city2.id]}
      subject{step_service.update! city_ids: [city.id]}

      it {expect{subject}.to change{CityApprove.count}.by(-1)}
    end

    describe 'add city with surcharge' do
      subject{step_service.update! city_ids: [city.id], cities_with_surcharge_ids: [city2.id]}

      it {expect{subject}.to change{CityApprove.with_surcharge.count}.by(1)}
    end

    describe 'remove city with surcharge' do
      before(:each) {step_service.update!  city_ids: [city.id], cities_with_surcharge_ids: [city.id, city2.id]}
      subject{step_service.update! cities_with_surcharge_ids: []}

      it {expect{subject}.to change{CityApprove.with_surcharge.count}.by(-1)}
    end
  end

end