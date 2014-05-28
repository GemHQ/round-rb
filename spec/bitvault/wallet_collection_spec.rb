require 'spec_helper'

describe BitVault::WalletCollection, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:application) { authed_client.user.applications[0] }
  let(:wallets) { application.wallets }

  describe '#create' do
    context 'with a valid passphrase and name' do
      let(:wallet) { wallets.create(passphrase: 'very insecure', name: 'my funds') }

      before(:each) {
        wallets.resource.stub(:create).and_return({})
      }

      it 'returns a Wallet model' do
        expect(wallet).to be_a_kind_of(BitVault::Wallet)
      end

      it 'adds a wallet to the collection' do
        expect { wallet }.to change(wallets, :count).by(1)
      end
    end

    context 'missing passphrase' do
      it 'raises an error' do
        expect { wallets.create(name: 'my funds') }.to raise_error(ArgumentError)
      end
    end

    context 'missing name' do
      it 'raises an error' do
        expect { wallets.create(passphrase: 'super_insecure') }.to raise_error(ArgumentError)
      end
    end
  end
end