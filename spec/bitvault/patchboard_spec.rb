require 'spec_helper'

describe BitVault::Patchboard, :vcr do
  describe '.authed_client' do
    context 'with BitVault-Token auth' do
      let(:client) { 
        BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/9foNkOXAx5o-jZKx672EAQ',
          api_token: 'j5kiETM6ZD0PAkybkHqagqT_S2zwRWUfe9Sn-o2Bwkg') 
      }

      it 'returns an authed client' do
        expect(client.resources).to_not be_nil
      end

      it 'sets the api_token' do
        expect(client.context.api_token).to_not be_nil
      end

      it 'sets the app_url' do
        expect(client.context.app_url).to_not be_nil
      end
    end

    context 'with basic auth' do
      let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
    
      it 'auths the client with basic auth' do
        expect(client.resources).to_not be_nil
      end

      it 'sets the email' do
        expect(client.context.email).to_not be_nil
      end

      it 'sets the password' do
        expect(client.context.password).to_not be_nil
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