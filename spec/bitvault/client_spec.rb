require 'spec_helper'

describe BitVault::Patchboard::Client, :vcr do
  describe '#user' do
    let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
    it 'returns a user model for the logged in user' do
      expect(client.user).to_not be_nil
      expect(client.user).to be_a_kind_of(BitVault::User)
    end
  end 

  describe '#application' do
    let(:client) {
      BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/jeZgADLToHXD5PDziaMk2g', 
        api_token: '9X7axU2VU36ssm4MoVN8rNjQBFVL2iLoM1VRFvlLyBM') 
    }
    it 'returns an application model' do
      expect(client.application).to_not be_nil
      expect(client.application).to be_a_kind_of(BitVault::Application)
    end
  end
end