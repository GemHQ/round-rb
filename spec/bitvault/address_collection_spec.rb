require 'spec_helper'

describe BitVault::AddressCollection, :vcr do
  let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:application) { client.user.applications['bitcoin_app'] }
  let(:account) { application.wallets['my funds'].accounts['office supplies'] }

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