require 'spec_helper'

describe BitVault::Wallet do
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
  let(:wallet) { BitVault::Wallet.new(resource: wallet_resource) }
  let(:passphrase) { 'very insecure' }
  let(:primary_seed) { double('primary_seed') }
  let(:multiwallet) { double('multiwallet') }

  before(:each) {
    allow(CoinOp::Crypto::PassphraseBox).to receive(:decrypt).and_return(primary_seed)
    allow(CoinOp::Bit::MultiWallet).to receive(:new).and_return(multiwallet)
  }

  describe '#initialize' do
    let(:resource) { double('resource') }
    let(:new_wallet) { BitVault::Wallet.new(resource: resource, multiwallet: multiwallet) }

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
      expect(wallet.accounts).to be_a_kind_of(BitVault::AccountCollection)
    end

    it 'only fetches once' do
      expect(wallet.resource.accounts).to receive(:list).once
      wallet.accounts
      wallet.accounts
    end
  end

  describe '#transfer' do
    let(:account_1) { double('account') }
    let(:account_2) { double('account') }
    let(:value) { 10_000 }

    context 'no source account provided' do
      it 'raises an error' do
        expect { wallet.transfer(destination: account_2, value: 10_000) }.to raise_error(ArgumentError)
      end
    end

    context 'no destination account provided' do
      it 'raises an error' do
        expect { wallet.transfer(source: account_1, value: 10_000) }.to raise_error(ArgumentError)
      end
    end

    context 'no value provided' do
      it 'raises an error' do
        expect { wallet.transfer(destination: account_2, source: account_1) }.to raise_error(ArgumentError)
      end
    end

    context 'locked wallet' do
      it 'raises an error' do
        expect { wallet.transfer(source: account_1, destination: account_2, value: value) }.to raise_error
      end
    end

    context 'valid arguments' do
      let(:transfer) { wallet.transfer(source: account_1, destination: account_2, value: value) }
      let(:unsigned_transfer) { double('unsigned_transfer') }
      let(:transaction) { double('transaction') }
      let(:signed_transfer) { double('signed_transfer') }
      let(:signatures) { double('signatures') }
      let(:hex_hash) { 'abcdef123456' }
      before(:each) {
        wallet.unlock(passphrase)
        allow(wallet.resource.transfers).to receive(:create).and_return(unsigned_transfer)
        allow(wallet.multiwallet).to receive(:signatures).and_return(signatures)
        allow(CoinOp::Bit::Transaction).to receive(:data).and_return(transaction)
        allow(unsigned_transfer).to receive(:sign) { signed_transfer }
        allow(transaction).to receive(:hex_hash) { hex_hash }
        allow(account_1).to receive(:url) { 'http://some.url/account1' }
        allow(account_2).to receive(:url) { 'http://some.url/account2' }
      }

      it 'calls create on transfers resource with the correct values' do
        expect(wallet.resource.transfers).to receive(:create).with(
          value: value,
          source: account_1.url,
          destination: account_2.url)
        transfer
      end

      it 'creates a native bitcoin transaction' do
        expect(CoinOp::Bit::Transaction).to receive(:data).with(unsigned_transfer)
        transfer
      end

      it 'signs the transfer' do
        expect(unsigned_transfer).to receive(:sign).with(
          transaction_hash: hex_hash,
          inputs: signatures)
        transfer
      end

      it 'returns a Transaction model' do
        expect(transfer).to be_a_kind_of(BitVault::Transaction)
      end
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