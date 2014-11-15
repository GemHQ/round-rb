require 'spec_helper'

describe Round::WalletCollection do
  let(:wallet_collection_resource) { double('wallet_collection_resource', list: []) }
  let(:wallets) { Round::WalletCollection.new(resource: wallet_collection_resource) }
  let(:wallet_resource) { double('wallet_resource', name: name) }
  let(:name) { 'new wallet' }
  let(:passphrase) { 'incredible_secret' }
  let(:network) { 'bitcoin_testnet' }
  let(:multiwallet) { double('multiwallet', trees: { primary: primary_seed, backup: backup_seed }) }
  let(:primary_seed) { double('primary_seed', to_serialized_address: double('primary_serialized_address')) }
  let(:backup_seed) { double('backup_seed', to_serialized_address: double('backup_serialized_address')) }
  let(:primary_address) { multiwallet.trees[:primary].to_serialized_address }
  let(:backup_address) { multiwallet.trees[:backup].to_serialized_address }
  let(:encrypted_seed) { double('encrypted_seed') }
  
  before(:each) {
    allow(CoinOp::Bit::MultiWallet).to receive(:generate).and_return(multiwallet)
    allow(CoinOp::Crypto::PassphraseBox).to receive(:encrypt).and_return(encrypted_seed)
    allow(wallets.resource).to receive(:create).and_return(wallet_resource)
  }

  describe '#create' do
    context 'with a valid passphrase and name' do
      let(:wallet) { wallets.create(name, passphrase) }

      it 'returns a Wallet model' do
        expect(wallet).to be_a_kind_of(Round::Wallet)
      end

      it 'adds a wallet to the collection' do
        expect { wallet }.to change(wallets, :count).by(1)
      end

      it 'sets the multiwallet on the model' do
        expect(CoinOp::Bit::MultiWallet).to receive(:generate).once
        expect(wallet.multiwallet).to eql(multiwallet)
      end
    end

    context 'missing passphrase' do
      it 'raises an error' do
        expect { wallets.create(name: name) }.to raise_error(ArgumentError)
      end
    end

    context 'missing name' do
      it 'raises an error' do
        expect { wallets.create(passphrase: passphrase) }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#create_wallet_resource' do
    let(:resource) { wallets.create_wallet_resource(multiwallet, passphrase, name, network ) }

    it 'calls resource.create with the correct values' do
      expect(wallets.resource).to receive(:create).with hash_including(
        name: name,
        network: network,
        backup_public_seed: backup_address,
        primary_public_seed: primary_address,
        primary_private_seed: encrypted_seed)
      resource
    end

    it 'returns the resource' do
      expect(resource).to eql(wallet_resource)
    end
  end
end