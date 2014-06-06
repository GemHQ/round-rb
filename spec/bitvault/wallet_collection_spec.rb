require 'spec_helper'

describe BitVault::WalletCollection, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:application) { authed_client.user.applications['bitcoin_app'] }
  let(:wallets) { application.wallets }
  let(:wallet_resource) { double('wallet_resource') }
  let(:name) { 'new wallet' }
  let(:passphrase) { 'very insecure' }
  
  before(:each) {
    allow(wallet_resource).to receive(:name) { name }
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

  describe '#generate_wallet' do
    let(:passphrase) { 'incredible_secret' }
    let(:name) { 'my_wallet' }
    let(:network) { 'bitcoin_testnet' }
    let(:multiwallet) { double('multiwallet', trees: { primary: primary_seed, backup: backup_seed }) }
    let(:primary_seed) { double('primary_seed', to_serialized_address: double('primary_serialized_address')) }
    let(:backup_seed) { double('backup_seed', to_serialized_address: double('backup_serialized_address')) }
    let(:primary_address) { multiwallet.trees[:primary].to_serialized_address }
    let(:backup_address) { multiwallet.trees[:backup].to_serialized_address }
    let(:encrypted_seed) { double('encrypted_seed') }
    let(:tuple) { wallets.generate_wallet(passphrase, name, network ) }

    before(:each) {
      CoinOp::Bit::MultiWallet.stub(:generate).and_return(multiwallet)
      CoinOp::Crypto::PassphraseBox.stub(:encrypt).and_return(encrypted_seed)
      wallets.resource.stub(:create).and_return(wallet_resource)
    }

    it 'calls resource.create with the correct values' do
      wallets.resource.should_receive(:create).with hash_including(
        name: name,
        network: network,
        backup_public_seed: backup_address,
        primary_public_seed: primary_address,
        primary_private_seed: encrypted_seed)
      tuple
    end

    it 'returns a tuple with the resource and multiwallet' do
      generated_multiwallet, generated_resource = tuple
      expect(generated_multiwallet).to eql(multiwallet)
      expect(generated_resource).to eql(wallet_resource)
    end
  end
end