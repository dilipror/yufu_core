require 'rails_helper'
require 'mongoid/criteria'
require 'yufu/mailer_attrs'

RSpec.describe MailerAttrs do

  describe '#user_attrs' do

    context 'user is not nil' do

      let(:user){create :user}

      subject{MailerAttrs.instance.user_attrs(user)}

      it{expect(subject[:client]).not_to be_nil}
    end

    context 'user is nil' do
      subject{MailerAttrs.instance.user_attrs(nil)}

      it{expect(subject[:client]).to be_nil}
    end
  end

  describe '#order_attrs' do


    context 'order is not nil' do
      let(:order){create :order_verbal}

      subject{MailerAttrs.instance.order_attrs(order)}

      it{expect(subject[:order_details]).not_to be_nil}
      it{expect(subject[:order_id]).not_to be_nil}
      it{expect(subject[:interpreter_name]).not_to be_nil}
      it{expect(subject[:order_details]).not_to be_nil}
      it{expect(subject[:phone_number]).not_to be_nil}
    end

    context 'order is nil' do

      subject{MailerAttrs.instance.order_attrs(nil)}

      it{expect(subject[:order_details]).to be_nil}
      it{expect(subject[:order_id]).to be_nil}
      it{expect(subject[:interpreter_name]).to be_nil}
      it{expect(subject[:phone_number]).to be_nil}

    end

  end

  describe '#confirm_attrs' do

    context 'everything is not nil' do

      let(:user){create :user}

      subject{MailerAttrs.instance.confirm_attrs('/confirmation/url', '/password/url')}

      it{expect(subject[:confirmation_url]).not_to be_nil}
      it{expect(subject[:password_url]).not_to be_nil}
    end

    context 'everything is nil' do
      subject{MailerAttrs.instance.confirm_attrs(nil, nil)}

      it{expect(subject[:confirmation_url]).to be_nil}
      it{expect(subject[:password_url]).to be_nil}
    end

  end

  describe '#other_attrs' do

    subject{MailerAttrs.instance.other_attrs}

    it{expect(subject[:root_url]).not_to be_nil}
    it{expect(subject[:dashboard_link]).not_to be_nil}

  end

  describe '#merged_attrs' do

    subject{MailerAttrs.instance.merged_attrs params}

    context 'no params' do
      let(:params){{}}

      it{expect(subject[:root_url]).not_to be_nil}
      it{expect(subject[:dashboard_link]).not_to be_nil}
      it{expect(subject[:order_details]).to be_nil}
      it{expect(subject[:order_id]).to be_nil}
      it{expect(subject[:interpreter_name]).to be_nil}
      it{expect(subject[:phone_number]).to be_nil}


    end

    context 'user params' do

      let(:user){create :user}

      let(:params){{user: user}}

      it{expect(subject[:root_url]).not_to be_nil}
      it{expect(subject[:dashboard_link]).not_to be_nil}
      it{expect(subject[:order_details]).to be_nil}
      it{expect(subject[:order_id]).to be_nil}
      it{expect(subject[:interpreter_name]).to be_nil}
      it{expect(subject[:phone_number]).to be_nil}
      it{expect(subject[:client]).not_to be_nil}

    end

  end
end