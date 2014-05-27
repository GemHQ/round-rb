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
  end
end