require 'spec_helper'

describe BitVault::Client, :vcr do

  let(:client) { BitVault::Client.discover }

  describe '.discover' do
    it 'discovers the API' do
      expect(client.resources).to_not be_nil
    end
  end

  describe '#authed_client' do
    it 'returns an authed client with basic auth' do
      authed_client = client.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret')
      expect(authed_client.context).to_not be_nil
      expect { authed_client.context.authorizer('Basic', nil, nil) }.to_not raise_error
    end
  end

end