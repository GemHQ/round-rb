require 'spec_helper'

describe BitVault::Patchboard::Client, :vcr do
  let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  describe '#user' do
    it 'returns a user model for the logged in user' do
      expect(client.user).to_not be_nil
      expect(client.user).to be_a_kind_of(BitVault::User)
    end
  end 

  describe '#application' do
    let(:application) { client.user.applications['bitcoin_app'] }
    let(:app_client) {
      BitVault::Patchboard.authed_client(app_url: application.url, api_token: application.api_token) 
    }
    it 'returns an application model' do
      expect(app_client.application).to_not be_nil
      expect(app_client.application).to be_a_kind_of(BitVault::Application)
    end
  end

  describe '#users' do
    it 'returns a UserCollection' do
      expect(client.users).to_not be_nil
      expect(client.users).to be_a_kind_of(BitVault::UserCollection)
    end
  end

  describe '#wallet' do
    let(:wallet_resource) { double('wallet_resource') }
    let(:wallet) {double('wallet', get: wallet_resource)}
    before(:each) {
      allow(client.resources).to receive(:wallet) { wallet }
    }

    it 'returns a Wallet' do
      url = 'http://bitvault.pandastrike.com/wallets/1234'
      expect(client.wallet(url: url)).to be_a_kind_of(BitVault::Wallet)
    end
  end
end