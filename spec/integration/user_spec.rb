require 'spec_helper'

describe Round::UserCollection do

  describe 'an application authed user' do
    # this user was not authenticated with the device
    let!(:device_id_and_user) { app_auth_user }
    let!(:user) { device_id_and_user[1] }
    let!(:device_id) { device_id_and_user[0] }

    it 'should have appropriate fields' do
      expect(user.email).to_not be_nil
      expect(user.first_name).to eq Round::TestHelpers::Auth::TestCreds::FIRST_NAME
      expect(user.last_name).to eq Round::TestHelpers::Auth::TestCreds::LAST_NAME
      expect(user.passphrase).to be_nil
    end

    it 'should not be able to access devices' do
      expect { user.devices }.to raise_error
    end

    it 'should not be able to access wallets' do
      expect { user.wallets }.to raise_error
    end
  end

  describe 'a device authed user' do
    unless Round::TestHelpers::Auth::TestCreds::EMAIL.nil? || 
        Round::TestHelpers::Auth::TestCreds::EMAIL == ''
      # having issues with a let!
      before :all do
        @user = device_auth_user
      end

      it 'should be able to create a wallet' do
        expect(@user.wallets.create('wallet', 'passphrase')).to_not be_nil
      end

      it 'has a wallet with an account' do
        wallet = @user.wallets.create('wallet1', 'passphrase1')
        expect(wallet.accounts.size).to eq 1
      end

      it 'can unlock your wallet' do
        wallet = @user.wallets.create('wallet2', 'passphrase2')
        expect { wallet.unlock('passphrase2') }.to_not raise_error
      end

      it 'can try to unlock a wallet unsuccessfully' do
        wallet = @user.wallets.create('wallet2', 'passphrase2')
        expect { wallet.unlock('incorrect') }.to raise_error
      end
    end
  end
end
