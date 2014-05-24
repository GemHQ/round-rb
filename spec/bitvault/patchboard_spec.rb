require 'spec_helper'

describe BitVault::Patchboard, :vcr do
  describe '.authed_client' do
    context 'with basic auth' do
      let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
    
      it 'auths the client with basic auth' do
        expect(client.resources).to_not be_nil
      end
    end

    context 'with no credentials' do
      let(:client) { BitVault::Patchboard.authed_client }
      it 'raises an error' do
        expect { client }.to raise_error
      end
    end
  end

end