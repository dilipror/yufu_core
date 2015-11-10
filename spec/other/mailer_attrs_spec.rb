require 'rails_helper'
require 'mongoid/criteria'
require 'lib/yufu/mailer_attrs'

RSpec.describe MailerAttrs do

  describe '#user_attrs' do

    let(:user){create :user}

    subject{MailerAttrs.instance.user_attrs(user)}

    it{expect(subject[:client]).not_to be_nil}
  end

end