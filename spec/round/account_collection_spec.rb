require 'spec_helper'

describe Round::AccountCollection do
  let(:account_resources) { [double('account', name: 'some account')] }
  let(:account_collection_resource) { double('account_collection_resource', list: account_resources) }
  let(:wallet_resource) { double('wallet_resource') }
  let(:wallet) { double('wallet') }
  let(:accounts) { Round::AccountCollection.new(resource: account_collection_resource, wallet: wallet) }
  let(:account) { accounts.create(name: 'office supplies') }

  describe '#initialize' do

    it 'raises an error if no wallet is provided' do
      expect { Round::AccountCollection.new(resource: account_collection_resource) }.to raise_error(ArgumentError)
    end

    it 'sets the wallet on each of the accounts' do
      accounts.each do |account|
        expect(account.wallet).to eql(wallet)
      end
    end
  end

  describe '#create' do
    let(:account_resource) { double('account_resource', name: 'new account') }
    before(:each) {
      allow(accounts.resource).to receive(:create).and_return(account_resource)
    }

    it 'returns an Account model' do
      expect(account).to be_a_kind_of(Round::Account)
    end

    it 'adds the new account to the collection' do
      expect{account}.to change(accounts, :count).by(1)
    end

    it 'calls resource create' do
      expect(accounts.resource).to receive(:create)
      account
    end
  end

end