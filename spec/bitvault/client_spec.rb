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
      BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/9foNkOXAx5o-jZKx672EAQ', 
        api_token: 'j5kiETM6ZD0PAkybkHqagqT_S2zwRWUfe9Sn-o2Bwkg') 
    }
    it 'returns an application model' do
      expect(client.application).to_not be_nil
      expect(client.application).to be_a_kind_of(BitVault::Application)
    end
  end
end