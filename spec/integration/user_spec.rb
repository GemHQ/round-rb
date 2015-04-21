require 'spec_helper'

describe Round::UserCollection do

  describe 'with identify auth' do
    # this user was not authenticated with the device
    let!(:device_token_and_user) { identify_auth_user }
    let!(:user) { device_token_and_user[1] }
    let!(:device_token) { device_token_and_user[0] }

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

      it 'has a wallet with an account' do
        wallet = @user.wallet
        expect(wallet.accounts.size).to eq 1
      end

      it 'can unlock your wallet' do
        wallet = @user.wallet
        expect { wallet.unlock(Round::TestHelpers::Auth::TestCreds::PASSPHRASE) }
          .to_not raise_error
      end

      it 'can try to unlock a wallet unsuccessfully' do
        expect { @user.wallet.unlock('incorrect') }.to raise_error
      end

      context 'that users account' do
        it 'should query transactions' do
          account = @user.wallet.accounts.first
          expect { account.transactions(type: 'outgoing', status: ['unsigned', 'unconfirmed']) }
            .to_not raise_error
        end
      end
    end
  end
end
