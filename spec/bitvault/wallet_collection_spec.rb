require 'spec_helper'

describe BitVault::WalletCollection do
  let(:wallet_collection_resource) { double('wallet_collection_resource', list: []) }
  let(:wallets) { BitVault::WalletCollection.new(resource: wallet_collection_resource) }
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
    CoinOp::Bit::MultiWallet.stub(:generate).and_return(multiwallet)
    CoinOp::Crypto::PassphraseBox.stub(:encrypt).and_return(encrypted_seed)
    wallets.resource.stub(:create).and_return(wallet_resource)
  }

  describe '#create' do
    context 'with a valid passphrase and name' do
      let(:wallet) { wallets.create(passphrase: passphrase, name: name) }

      it 'returns a Wallet model' do
        expect(wallet).to be_a_kind_of(BitVault::Wallet)
      end

      it 'adds a wallet to the collection' do
        expect { wallet }.to change(wallets, :count).by(1)
      end

      it 'sets the multiwallet on the model' do
        CoinOp::Bit::MultiWallet.should_receive(:generate).once
        expect(wallet.multiwallet).to eql(multiwallet)
      end

      context 'with an existing wallet' do
        let(:wallet) { wallets.create(passphrase: passphrase, name: name, multiwallet: multiwallet) }

        it 'sets the existing wallet on the model' do
          CoinOp::Bit::MultiWallet.should_not_receive(:generate)
          expect(wallet.multiwallet).to eql(multiwallet)
        end
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
      wallets.resource.should_receive(:create).with hash_including(
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