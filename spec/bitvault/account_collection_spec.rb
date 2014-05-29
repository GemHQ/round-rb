require 'spec_helper'

describe BitVault::AccountCollection, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:accounts) { authed_client.user.applications[0].wallets[0].accounts }
  let(:account) { accounts.create(name: 'office supplies') }

  describe '#create' do
    before(:each) {
      accounts.resource.stub(:create).and_return({})
    }

    it 'returns an Account model' do
      expect(account).to be_a_kind_of(BitVault::Account)
    end

    it 'adds the new account to the collection' do
      expect{account}.to change(accounts, :count).by(1)
    end

    it 'calls resource create' do
      accounts.resource.should_receive(:create)
      account
    end
  end

end