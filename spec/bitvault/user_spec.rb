require 'spec_helper'

describe BitVault::User, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:resource) {
    authed_client.user
  }
  let(:user) { BitVault::User.new(resource: resource) }

  describe '#initialize' do
    context 'with a valid User resource' do
      it 'should set the resource' do
        expect(user.resource).to_not be_nil
      end
    end
  end

  describe '#update' do
    it 'delegates to the resource' do
      user.resource.should_receive(:update).with({first_name: 'Julian'})
      user.update(first_name: 'Julian')
    end
  end
end