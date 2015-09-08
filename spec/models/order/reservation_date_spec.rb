require 'rails_helper'

RSpec.describe Order::ReservationDate, :type => :model do

  describe '#original_price' do
    let(:reservation_date) {order.reservation_dates.first}
    let(:day_cost) {order.language.verbal_price(order.level)}

    subject{reservation_date.original_price}

    context 'when hours = 8' do
      let(:order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, hours: 8)]}
      it {is_expected.to eq day_cost * 8}
    end

    context 'when hours < 8' do
      let(:order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, hours: 4)]}
      it {is_expected.to eq day_cost * 4 * 1.5}
    end

    context 'when hours > 8' do
      let(:order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, hours: 10)]}
      it {is_expected.to eq day_cost * 8 + day_cost * 2 * 1.5}
    end

  end

  describe '#original_price_without_overtime' do

    let(:order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, hours: hours)]}

    let(:reservation_date) {order.reservation_dates.first}

    subject {reservation_date.original_price_without_overtime}

    before(:each) {Language.any_instance.stub(:verbal_price).and_return(10)}

    context 'overtime' do
      let(:hours){10}

      it {is_expected.to eq(100)}

    end

    context 'hours lt 8' do
      let(:hours){4}

      it{is_expected.to eq (4 * 10 * 1.5)}
    end

    context 'no overtime' do
       let(:hours){8}

       it {is_expected.to eq(80)}

    end
  end

  describe '#overtime_price' do

    before(:each) {Language.any_instance.stub(:verbal_price).and_return(10)}

    subject{reservation_date.overtime_price}

    let(:order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, hours: hours)]}
    let(:reservation_date) {order.reservation_dates.first}

    RSpec.shared_examples 'standard overtime' do
      context 'no overtime' do
        let(:hours){8}

        it{is_expected.to eq(0)}
      end

      context 'overtime' do
        let(:hours){12}

        it{is_expected.to eq((12 - 8) * 10 * 0.5)}
      end
    end

    context 'pass is_first_date as true' do
      subject{reservation_date.overtime_price is_first_date: true, work_start_at: work_start_at}

      context 'all work in work time range' do
        let(:work_start_at){7}
        it_behaves_like 'standard overtime'
      end

      context 'has work after working day' do
        let(:work_start_at){20}

        context 'hours gt 8' do
          let(:hours){10}
          it 'is sum of over hours (10 - 8) and work outside working time multiplied by lang cost and coef 0.5' do
            is_expected.to eq(((10 - 8) + (20 + 10 - 21)) * 10 * 0.5)
          end
        end

        context 'hours lte 8' do
          let(:hours){8}
          it 'is work outside working time multiplied by lang cost and coef 0.5' do
            is_expected.to eq((20 + 8 - 21) * 10 * 0.5)
          end
        end
      end

      context 'has work before working day' do
        let(:work_start_at){6}

        context 'hours gt 8' do
          let(:hours){10}
          it 'is sum of over hours (10 - 8) and work outside working time multiplied by lang cost and coef 0.5' do
            is_expected.to eq(((10 - 8) + (7 - 6)) * 10 * 0.5)
          end
        end

        context 'hours lte 8' do
          let(:hours){8}
          it 'is work outside working time multiplied by lang cost and coef 0.5' do
            is_expected.to eq((7 - 6) * 10 * 0.5)
          end
        end
      end

      context 'has work after and before working day' do
        let(:work_start_at){6}

        context 'hours gt 8' do
          let(:hours){16}
          it 'is sum of over hours (10 - 8) and work outside working time multiplied by lang cost and coef 0.5' do
            is_expected.to eq(((16 - 8) + (7 - 6) + (16 + 6 - 21)) * 10 * 0.5)
          end
        end
      end
    end

    context 'do not pass is_first_date or pass it as false' do
      it_behaves_like 'standard overtime'
    end
  end

  describe '#available?' do
    let(:translator) {create :full_approved_profile_translator}
    let(:service) {translator.services.first}
    let(:location) {translator.city_approves.first.city}
    let(:reservation_date) do
      build :order_reservation_date,
            order_verbal: create(:order_verbal, language: service.language, level: service.level, location: location)
    end

    before(:each) do
      translator.city_approves.first.update translator_id: translator.id
    end

    context 'not pass arguments' do

      subject{reservation_date.available?}

      context 'there is translator who support lvl and language set for reservation_date' do
        it{is_expected.to be_truthy}
      end

      context 'there is no translator who support lvl and language set for reservation_date' do
        let(:reservation_date){build(:order_reservation_date,
                      order_verbal: create(:order_verbal, location: location))}
        it{is_expected.to be_falsey}
      end
    end

    context 'pass arguments' do
      let(:reservation_date) {build :order_reservation_date, order_verbal: create(:order_verbal, reservation_dates: [])}

      subject{reservation_date.available? language, location, level}

      context 'there is translator who support passed lvl and language' do
        let(:language) {service.language}
        let(:level)    {service.level}

        it{is_expected.to be_truthy}
      end

      context 'there is no translator who support passed lvl and language' do
        let(:language) {create :language}
        let(:level) {'guide'}

        it{is_expected.to be_falsey}
      end
    end

  end

  # Deprecated
  describe '#available_level' do
    subject{reservation_date.available_level}
    context 'current level is not available' do
      let(:city) {create :city}

      let(:step) {build :profile_steps_service, hsk_level: 4, cities: [city]}
      let(:translator) {create :profile_translator, profile_steps_service: step, city: city}
      # let(:translator) {create :profile_translator }
      let(:translator_guide) {create :profile_translator,
                                     services: [(build :service,
                                                       language: translator.services.first.language, level: 'guide')]}

      let(:reservation_date) do
        translator_guide
        language = translator.profile_steps_service.services.first.language
        lvl = 'business'
        cr = create :order_language_criterion, language: language, level: lvl
        build :order_reservation_date,
              order_verbal: create(:order_verbal, language: language, level: lvl, location: translator.profile_steps_service.cities.first)
      end

      # it 'returns max available level' do
      #   is_expected.to eq('expert')
      # end
    end
  end

  describe 'validates a pair of date and order_id' do
    let(:order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, date: Date.parse('01.01.2015'))]}
    let(:new_order) {create :order_verbal, reservation_dates: [build(:order_reservation_date, date: Date.parse('10.10.2015'))]}
    it 'correct date' do
      new_date = build :order_reservation_date, order_verbal: order, date: Date.parse('02.01.2015')
      expect(new_date.valid?).to be_truthy
    end

    it 'incorrect date' do
      new_date = build :order_reservation_date, order_verbal: order, date: Date.parse('01.01.2015')
      expect(new_date.valid?).to be_falsey
    end

  end
end