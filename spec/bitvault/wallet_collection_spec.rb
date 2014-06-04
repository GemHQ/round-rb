require 'spec_helper'

describe BitVault::WalletCollection, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:application) { authed_client.user.applications[0] }
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

  describe '#create_wallet_resource' do
    let(:passphrase) { 'incredible_secret' }
    let(:name) { 'my_wallet' }
    let(:network) { 'bitcoin_testnet' }
    let(:resource) { wallets.create_wallet_resource(passphrase, name, network ) }
    let(:multi_wallet) { CoinOp::Bit::MultiWallet.generate [:primary, :backup] }
    let(:primary_address) { multi_wallet.trees[:primary].to_serialized_address }
    let(:backup_address) { multi_wallet.trees[:backup].to_serialized_address }
    let(:primary_seed) { multi_wallet.trees[:primary].to_serialized_address(:private) }
    let(:encrypted_seed) { CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed) }

    it 'calls resource.create with the correct values' do
      multi_wallet
      encrypted_seed
      CoinOp::Bit::MultiWallet.stub(:generate).and_return(multi_wallet)
      CoinOp::Crypto::PassphraseBox.stub(:encrypt).and_return(encrypted_seed)
      wallets.resource.should_receive(:create).with hash_including(
        name: name,
        network: network,
        backup_public_seed: backup_address,
        primary_public_seed: primary_address,
        primary_private_seed: encrypted_seed)
      resource
    end
  end
end