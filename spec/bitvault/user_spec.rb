require 'spec_helper'

describe BitVault::User, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:user) { authed_client.user }

  describe '#initialize' do
    context 'with a valid User resource' do
      it 'should set the resource' do
        expect(user.resource).to_not be_nil
        expect(user.resource).to be_a_kind_of(Patchboard::Resource)
      end
    end
  end

  describe 'delegate methods' do
    it 'delegates update to the resource' do
      user.resource.should_receive(:update).with({first_name: 'Julian'})
      user.update(first_name: 'Julian')
    end

    it 'delegates email to the resource' do
      user.resource.should_receive(:email)
      user.email
    end

    it 'delegates first_name to the resource' do
      user.resource.should_receive(:first_name)
      user.first_name
    end

    it 'delegates last_name to the resource' do
      user.resource.should_receive(:last_name)
      user.last_name
    end
  end

  describe '#applications' do
    before(:each) { 
      user.resource.applications.stub(:list).and_return([])
    }
    
    it 'returns an ApplicationCollection' do
      expect(user.applications).to be_a_kind_of(BitVault::ApplicationCollection)
    end

    it 'only fetches once' do
      user.resource.applications.should_receive(:list).once
      user.applications
      user.applications
    end

    it 'fetches twice when refresh is passed' do
      user.resource.applications.should_receive(:list).twice
      user.applications
      user.applications(refresh: true)
    end
  end
end