require 'rails_helper'

RSpec.describe Group do

  let(:user){create :user}
  let(:ability_one){build :permission, action: 'create', subject_class: 'Office'}
  let(:ability_two){build :permission, action: 'destroy', subject_class: 'Profile'}
  let(:not_user_group){create :group, permissions: [ability_one]}

  let(:ability) do
    Ability.new(user)
  end

  subject{ability.can? action, sub, id: sub_id}


  describe 'group permission' do

    before(:each) do
      user.groups.create permissions: [ability_two]
    end

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

    context 'has group' do
      let(:action){:destroy}
      let(:sub){Profile}
      let(:sub_id){nil}
      include_examples 'can case'
    end

    context 'has not group' do
      let(:action){:create}
      let(:sub){Office}
      let(:sub_id){nil}
      include_examples 'can not case'
    end

  end



end