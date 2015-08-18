require 'rails_helper'

RSpec.describe Permission do
  let(:user){create :user}

  let(:ability) do
    Ability.new(user)
  end

  subject{ability.can? action, sub, id: sub_id}

  shared_examples 'can case' do
    it 'can' do
      expect(subject).to be_truthy
    end
  end

  shared_examples 'can not case' do
    it 'can not' do
      expect(subject).to be_falsey
    end
  end

  context 'manage all' do
    let(:action){:manage}
    let(:sub){:all}
    let(:sub_id){nil}

    before(:each) do
      user.permissions.create action: 'manage', subject_class: :all
    end

    include_examples 'can case'

  end

  context 'create office' do
    let(:action){:create}
    let(:sub){Office}
    let(:sub_id){nil}

    before(:each) do
      user.permissions.create action: 'create', subject_class: 'Office'
    end

    include_examples 'can case'
  end


  context 'delete profile with id' do
    let(:profile){user.profile_client}
    let(:action){:delete}
    let(:sub){Profile}
    let(:sub_id){profile.id}

    before(:each) do
      user.permissions.create action: 'delete', subject_class: 'Profile', subject_id: profile.id
    end

    include_examples 'can case'
  end


  context 'can not create office' do
    let(:profile){user.profile_client}
    let(:action){:create}
    let(:sub){Office}
    let(:sub_id){nil}

    before(:each) do
      user.permissions.create action: 'delete', subject_class: 'Profile', subject_id: profile.id
    end

    include_examples 'can not case'
  end
end
