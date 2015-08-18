require 'rails_helper'

RSpec.describe Translation, :type => :model do



  describe '.keys' do
    subject{Translation.keys}
    it {is_expected.not_to be_empty}
  end

  describe '.new' do
    subject{Translation.new('ready', :ru, 'redis', '', '')}
    it {is_expected.to be_a Translation}
    it 'creates value as translation key in requested locale' do
      expect(subject.value).to eq(I18n.t('ready', locale: :ru))
    end
  end

  describe '#save' do

    after(:each) do
      I18n.backend.store_translations(:ru, {:directions_list => 'List of destinations'}, escape: false)
      I18nJsExportWorker.perform_async
    end

    subject{translation.save}
    let(:city) {create :city, name: 'Moscow'}

    context 'storage id mongo' do
      let(:translation) {Translation.new "City.name.#{city.id}", :ru, 'mongo', 'Moscow', 'Москва'}
      # (key, locale, storage, org, vl)
      it {expect{subject}.to change{city.reload.name_translations['ru']}.to('Москва')}
    end

    context 'storage id redis' do
      let(:translation) {Translation.new :directions_list, :ru, 'redis', '', 'q'}
      it {expect{subject}.to change{I18n.t :directions_list, locale: :ru}.to ('q')}
    end
  end

end
