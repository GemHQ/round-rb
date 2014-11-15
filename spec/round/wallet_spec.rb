require 'spec_helper'

describe Round::Wallet do
  let(:seed) { double('seed') }
  let(:accounts_resource) { double('accounts_resource', list: []) }
  let(:transfers_resource) { double('transfers_resource') }
  let(:wallet_resource) { 
    double('wallet_resource', 
      accounts: accounts_resource,
      primary_private_seed: seed,
      cosigner_public_seed: seed,
      backup_public_seed: seed,
      transfers: transfers_resource) 
  }
  let(:wallet) { Round::Wallet.new(resource: wallet_resource) }
  let(:passphrase) { 'very insecure' }
  let(:primary_seed) { double('primary_seed') }
  let(:multiwallet) { double('multiwallet') }

  before(:each) {
    allow(CoinOp::Crypto::PassphraseBox).to receive(:decrypt).and_return(primary_seed)
    allow(CoinOp::Bit::MultiWallet).to receive(:new).and_return(multiwallet)
  }

  describe '#initialize' do
    let(:resource) { double('resource') }
    let(:new_wallet) { Round::Wallet.new(resource: resource, multiwallet: multiwallet) }

    it 'sets the multiwallet when present' do
      expect(new_wallet.multiwallet).to eql(multiwallet)
    end
  end

  describe '#unlock' do
    it 'populates the multiwallet' do
      wallet.unlock(passphrase)
      expect(wallet.multiwallet).to eql(multiwallet)
    end
  end

  describe '#accounts' do
    it 'returns an AccountCollection' do
      expect(wallet.accounts).to be_a_kind_of(Round::AccountCollection)
    end

    it 'only fetches once' do
      expect(wallet.resource.accounts).to receive(:list).once
      wallet.accounts
      wallet.accounts
    end
  end
  
  describe 'delegate methods' do
    [:name, :network, :cosigner_public_seed, 
      :backup_public_seed, :primary_public_seed,
      :primary_private_seed].each do |method|
      it "delegates #{method} to resource" do
        expect(wallet.resource).to receive(method)
        wallet.send(method)
      end
    end
  end
end