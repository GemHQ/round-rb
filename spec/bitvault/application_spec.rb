require 'spec_helper'

describe BitVault::Application, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:user) { authed_client.user }
  let(:application) { user.applications['bitcoin_app'] }

  describe 'delegate methods' do
    it 'delegates name to resource' do
      expect(application.name).to eql('bitcoin_app')
    end

    it 'delegates callback_url to resource' do
      expect(application.callback_url).to eql('http://someapp.com/callback')
    end

    it 'delegates api_token to resource' do
      application.resource.should_receive(:api_token)
      application.api_token
    end

    it 'delegates update to resource' do
      application.resource.stub(:update).and_return(application.resource)
      application.resource.should_receive(:update)
      application.update(name: 'other_app')
    end
  end

  describe '#wallets' do
    before(:each) { 
      application.resource.wallets.stub(:list).and_return([])
    }

    it 'returns a WalletCollection' do
      expect(application.wallets).to be_a_kind_of(BitVault::WalletCollection)
    end

    it 'only fetches once' do
      application.resource.wallets.should_receive(:list).once
      application.wallets
      application.wallets
    end
  end
end