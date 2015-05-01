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
          expect { account.transactions(type: 'outgoing', status: ['unsigned', 'unconfirmed']) }
            .to_not raise_error
        end
      end
    end
  end
end
