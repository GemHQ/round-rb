require 'spec_helper'

describe BitVault::Wallet, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:wallet) { authed_client.user.applications[0].wallets['my funds'] }
  let(:passphrase) { 'very insecure' }
  let(:primary_seed) { CoinOp::Crypto::PassphraseBox.decrypt(passphrase, wallet.resource.primary_private_seed) }

  describe '#unlock' do
    it 'populates the multiwallet' do
      wallet.unlock(passphrase)
      expect(wallet.multiwallet).to_not be_nil
      expect(wallet.multiwallet).to be_a_kind_of(CoinOp::Bit::MultiWallet)
    end

    it 'decrypts the wallet' do
      wallet.unlock(passphrase)
      expect(wallet.multiwallet.trees[:primary].to_serialized_address(:private)).to eql(primary_seed)
    end
  end

  describe '#accounts' do
    before(:each) { 
      wallet.resource.accounts.stub(:list).and_return([])
    }

    it 'returns an AccountCollection' do
      expect(wallet.accounts).to be_a_kind_of(BitVault::AccountCollection)
    end

    it 'only fetches once' do
      wallet.resource.accounts.should_receive(:list).once
      wallet.accounts
      wallet.accounts
    end
  end

  describe '#transfer' do
    let(:account_1) { double('account') }
    let(:account_2) { double('account') }
    let(:amount) { 10_000 }

    context 'no source account provided' do
      it 'raises an error' do
        expect { wallet.transfer(destination: account_2, amount: 10_000) }.to raise_error(ArgumentError)
      end
    end

    context 'no destination account provided' do
      it 'raises an error' do
        expect { wallet.transfer(source: account_1, amount: 10_000) }.to raise_error(ArgumentError)
      end
    end

    context 'no amount provided' do
      it 'raises an error' do
        expect { wallet.transfer(destination: account_2, source: account_1) }.to raise_error(ArgumentError)
      end
    end

    context 'locked wallet' do
      it 'raises an error' do
        expect { wallet.transfer(source: account_1, destination: account_2, amount: amount) }.to raise_error
      end
    end

    context 'valid arguments' do
      let(:transfer) { wallet.transfer(source: account_1, destination: account_2, amount: amount) }
      let(:unsigned_transfer) { double('unsigned_transfer') }
      let(:transaction) { double('transaction') }
      let(:signed_transfer) { double('signed_transfer') }
      let(:signatures) { double('signatures') }
      before(:each) {
        wallet.unlock(passphrase)
        wallet.resource.transfers.stub(:create).and_return(unsigned_transfer)
        wallet.multiwallet.stub(:signatures).and_return(signatures)
        CoinOp::Bit::Transaction.stub(:data).and_return(transaction)
        allow(unsigned_transfer).to receive(:sign) { signed_transfer }
        allow(transaction).to receive(:base58_hash) { 'abcdef123456' }
        allow(account_1).to receive(:url) { 'http://some.url/account1' }
        allow(account_2).to receive(:url) { 'http://some.url/account2' }
      }

      it 'calls create on transfers resource with the correct values' do
        wallet.resource.transfers.should_receive(:create).with(
          value: amount,
          source: account_1.url,
          destination: account_2.url)
        transfer
      end

      it 'creates a native bitcoin transaction' do
        CoinOp::Bit::Transaction.should_receive(:data).with(unsigned_transfer)
        transfer
      end

      it 'signs the transfer' do
        unsigned_transfer.should_receive(:sign).with(
          transaction_hash: 'abcdef123456',
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
        wallet.resource.should_receive(method)
        wallet.send(method)
      end
    end
  end
end