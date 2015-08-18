require 'rails_helper'

RSpec.describe Order::CarRent, :type => :model do
  describe '.cost' do
    let(:car_rent) {build :car_rent}
    subject{car_rent.cost}
    it {expect(subject).to eq(car_rent.car.cost * car_rent.duration)}
  end
end
