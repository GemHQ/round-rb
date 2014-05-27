require 'spec_helper'

describe BitVault::Application, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:user) { authed_client.user }
  let(:application) { user.applications[0] }

  describe 'delegate methods' do
    it 'delegates name to resource' do
      expect(application.name).to eql('bitcoin_app')
    end

    it 'delegates callback_url to resource' do
      expect(application.callback_url).to eql('http://someapp.com/callback')
    end

    it 'delegates update to resource' do
      application.resource.stub(:update).and_return(application.resource)
      application.resource.should_receive(:update)
      application.update(name: 'other_app')
    end
  end

  describe '#wallets' do
    it 'returns a WalletCollection' do
      expect(application.wallets).to be_a_kind_of(BitVault::WalletCollection)
    end
  end
end