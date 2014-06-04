require 'spec_helper'

describe BitVault::AccountCollection, :vcr do
  let(:authed_client) { 
    BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/jeZgADLToHXD5PDziaMk2g', 
      api_token: '9X7axU2VU36ssm4MoVN8rNjQBFVL2iLoM1VRFvlLyBM') 
  }
  let(:wallet) { authed_client.application.wallets['my funds'] }
  let(:accounts) { wallet.accounts }
  let(:account) { accounts.create(name: 'office supplies') }

  describe '#initialize' do
    it 'raises an error if no wallet is provided' do
      expect {
        collection = BitVault::AccountCollection.new(resource: wallet.resource.accounts)  
      }.to raise_error(ArgumentError)
    end

    it 'sets the wallet on each of the accounts' do
      wallet.accounts.each do |name, account|
        expect(account.wallet).to eql(wallet)
      end
    end
  end

  describe '#create' do
    let(:account_resource) { double('account_resource') }
    before(:each) {
      allow(account_resource).to receive(:name) { 'new account' }
      accounts.resource.stub(:create).and_return(account_resource)
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