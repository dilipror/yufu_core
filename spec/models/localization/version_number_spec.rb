require 'rails_helper'

RSpec.describe Localization::VersionNumber, type: :model do
  describe '.create' do
    subject{ Localization::VersionNumber.create name: '111' }

    it{ expect{subject}.to change{Localization::Version.count}.by(1)}
  end
end