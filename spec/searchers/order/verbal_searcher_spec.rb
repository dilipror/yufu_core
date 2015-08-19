require 'rails_helper'

RSpec.describe Searchers::Order::VerbalSearcher  do
  describe '#search' do
    let(:translator){create :profile_translator}
    let(:active_queue){create :order_verbal_translators_queue, lock_to: Date.yesterday, translators: [translator]}
    let(:inactive_queue){create :order_verbal_translators_queue, lock_to: Date.tomorrow, translators: [translator]}

    before(:each){active_queue; inactive_queue}

    subject{ Searchers::Order::VerbalSearcher.new(translator).search }

    it{is_expected.to include active_queue.order_verbal}
    it{is_expected.not_to include inactive_queue.order_verbal}
  end
end