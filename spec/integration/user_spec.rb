require 'spec_helper'

describe Round::UserCollection do

  describe 'a device authed user' do
    unless Round::TestHelpers::Auth::TestCreds::EMAIL.nil? || 
        Round::TestHelpers::Auth::TestCreds::EMAIL == ''
      # having issues with a let!
      before :all do
        @user = device_auth_user
      end

      it 'has a wallet with an account' do
        wallet = @user.wallet
        expect(wallet.accounts.size).to eq 1
      end

      it 'can unlock your wallet' do
        wallet = @user.wallet
        expect do
          wallet.unlock(Round::TestHelpers::Auth::TestCreds::PASSPHRASE)
        end.to_not raise_error
      end

      it 'can try to unlock a wallet unsuccessfully' do
        expect { @user.wallet.unlock('incorrect') }.to raise_error
      end

      context 'that users account' do
        it 'should query transactions' do
          account = @user.wallet.accounts.first
          expect do
            account.transactions(type: 'outgoing', status: ['unsigned', 'unconfirmed'])
          end.to_not raise_error
        end

        it 'should create different kinds of addresses' do
          @user.wallet.unlock(Round::TestHelpers::Auth::TestCreds::PASSPHRASE)
          bitcoin_account = @user.wallet.accounts.create(name: 'bitcoin', network: :bitcoin)
          testnet_account = @user.wallet.accounts.create(name: 'testnet', network: :bitcoin_testnet)
          litecoin_account = @user.wallet.accounts.create(name: 'litecoin', network: :litecoin)
          dogecoin_account = @user.wallet.accounts.create(name: 'dogecoin', network: :dogecoin)
          bitcoin_address = bitcoin_account.addresses.create.string
          testnet_address = testnet_account.addresses.create.string
          litecoin_address = litecoin_account.addresses.create.string
          dogecoin_address = dogecoin_account.addresses.create.string
          expect(bitcoin_address[0]).to eq '3'
          expect(testnet_address[0]).to eq '2'
          #puts @user.email
          #puts Round::TestHelpers::Auth::TestCreds::PASSPHRASE
          #puts 'ahhhh'
          #puts bitcoin_address
          #puts testnet_address
          #binding.pry
          #puts 2
        end
      end
    end
  end
end
