require 'rails_helper'
RSpec.describe OrderVerbalQueueFactoryWorker, :type => :worker do
  let(:city){create :city}
  let(:language){create :language, senior: senior}
  let(:china){create :china}

  let(:agent) do
      create :user, profile_translator: create(:profile_translator,
                                               services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                               city_approves: [build(:city_approve, is_approved: true, city: city)])
  end
  let(:native_chinese_translator) do
    create :user, profile_translator: create(:profile_translator,
                                             profile_steps_language: build(:profile_steps_language, citizenship: china),
                                             services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                             city_approves: [build(:city_approve, is_approved: true, city: city)]
                )
  end
  let(:senior){create(:profile_translator)}
  let(:private_translator) do
    create :user, profile_translator: create(:profile_translator,
                                             services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                             city_approves: [build(:city_approve, is_approved: true, city: city)]
                )
  end
  let(:order){create :wait_offers_order, location: city, language: language, want_native_chinese: true, referral_link: agent.referral_link}

  before(:each){private_translator; native_chinese_translator}

  describe 'perform' do
    subject{OrderVerbalQueueFactoryWorker.new.perform order.id, 'en'}

    it{expect{subject}.to change{order.reload.translators_queues.count}.by(4)}

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
