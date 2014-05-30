require 'spec_helper'

describe BitVault::AccountCollection, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:wallet) { authed_client.user.applications[0].wallets[0] }
  let(:accounts) { wallet.accounts }
  let(:account) { accounts.create(name: 'office supplies', wallet: wallet) }

  describe '#initialize' do
    it 'raises an error if no wallet is provided' do
      expect {
        collection = BitVault::AccountCollection.new(resource: wallet.resource.accounts)  
      }.to raise_error(ArgumentError)
    end

    it 'sets the wallet on each of the accounts' do
      wallet.accounts.each do |account|
        expect(account.wallet).to eql(wallet)
      end
    end
  end

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