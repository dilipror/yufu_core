require 'rails_helper'
RSpec.describe OrderVerbalQueueFactoryWorker, :type => :worker do
  let(:city){create :city}
  let(:language){create :language}
  let(:china){create :china}


  let(:private_translator) do
    create :user, profile_translator: create(:profile_translator,
                                             services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                             city_approves: [build(:city_approve, is_approved: true, city: city)]
                )
  end

  let(:agent) do
    create :user, profile_translator: create(:profile_translator,
                                             services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                             city_approves: [build(:city_approve, is_approved: true, city: city)])
  end
  let(:order){create :wait_offers_order, location: city, language: language, want_native_chinese: true, referral_link: agent.referral_link}

  describe 'perform' do
    subject{OrderVerbalQueueFactoryWorker.new.perform order.id, 'en'}

    context 'native' do
      let!(:native_chinese_translator) do
        create :user, profile_translator: create(:profile_translator,
                                                 profile_steps_language: build(:profile_steps_language, citizenship: china),
                                                 services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                                 city_approves: [build(:city_approve, is_approved: true, city: city)]
                    )
      end
      context 'when want_native_chinese' do
        let(:order){create :wait_offers_order, location: city, language: language, want_native_chinese: true}
        it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
      end

      context 'when want_native_chinese with surcharge' do
        let(:order){create :wait_offers_order, location: city, language: language, include_near_city: true, want_native_chinese: true}
        it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
      end
    end

    context 'agent' do

      context 'when order without surcharge' do
        let!(:agent) do
          create :user, profile_translator: create(:profile_translator,
                                                   services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                                   city_approves: [build(:city_approve, is_approved: true, city: city)])
        end
        let(:order){create :wait_offers_order, location: city, language: language, referral_link: agent.referral_link, include_near_city: false}
        it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
      end

      context 'when order with surcharge' do
        let!(:agent) do
          create :user, profile_translator: create(:profile_translator,
                                                   services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                                   city_approves: [build(:city_approve, is_approved: true, city: city, with_surcharge: true)])
        end
        let(:order){create :wait_offers_order, location: city, language: language, referral_link: agent.referral_link, include_near_city: true}
        it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
      end

    end

    context 'senior' do

      before(:each) {language.update_attributes senior: senior}
      context 'when order without surcharge' do
        let!(:senior){create :profile_translator, city_approves: [build(:city_approve, is_approved: true, city: city)],
                             services: [build(:service, is_approved: true, language: language, level: 'guide')]}
        let(:order){create :wait_offers_order, location: city, language: language, include_near_city: false}
        it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
      end

      context 'when order with surcharge' do
        let!(:senior){create :profile_translator, city_approves: [build(:city_approve, is_approved: true, city: city, with_surcharge: true)],
                             services: [build(:service, is_approved: true, language: language, level: 'guide')]}
        let(:order){create :wait_offers_order, location: city, language: language, include_near_city: true}
        it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
      end
    end



    it 'set truthy lock dates for queues' do
      subject
      last_date = nil
      order.reload.translators_queues.each do |q|
        expect(q.lock_to).to eq (last_date + 30.minutes) if last_date.present?
        last_date = q.lock_to
      end
    end
  end
end
