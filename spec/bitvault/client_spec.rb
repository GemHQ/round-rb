require 'spec_helper'

describe BitVault::Patchboard::Client, :vcr do
  let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }

  describe '#user' do
    it 'returns a user model for the logged in user' do
      expect(client.user).to_not be_nil
      expect(client.user).to be_a_kind_of(BitVault::User)
    end
  end 
end