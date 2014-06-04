require 'spec_helper'

describe BitVault::AddressCollection, :vcr do
  let(:authed_client) {
    BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/jeZgADLToHXD5PDziaMk2g', 
      api_token: '9X7axU2VU36ssm4MoVN8rNjQBFVL2iLoM1VRFvlLyBM') 
  }
  let(:account) { authed_client.application.wallets['my funds'].accounts['office supplies'] }

  describe '#create' do
    before(:each) {
      account.addresses.resource.stub(:create).and_return({})
    }

    let(:address) { account.addresses.create }

    it 'delegates to the resource' do
      account.addresses.resource.should_receive(:create)
      address
    end

    it 'returns an address object' do
      expect(address).to be_a_kind_of(BitVault::Address)
    end

    it 'increases the address count' do
      expect { address }.to change(account.addresses, :count).by(1)
    end
  end
end