require 'rails_helper'

RSpec.describe Notificable do
  before :all do
    class ExampleClass
      include Mongoid::Document
      include Notificable
      has_notification_about :create, observers: User.all, message: 'hi'
      after_create :notify_about_create
    end
  end
  let(:user) {create :user}
  subject{ExampleClass.create}

  it 'creates new instance of notification for user' do
    expect{subject}.to change{user.reload.notifications.count}.by(1)
  end
  it 'assigns new notification with object' do
    user
    obj = subject
    expect(user.reload.notifications.last.object).to eq(obj)
  end


end