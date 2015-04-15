require 'spec_helper'

describe Round::Application do
  let!(:app_and_client) { app_auth_client }
  let!(:app) { app_and_client[0] }
  let!(:client) { app_and_client[1] }

  describe 'application auth' do
    it 'should create wallets' do
      wallet = app.wallets.create('name', 'password')
      expect { wallet.unlock('password') }.to_not raise_error
      expect { wallet.unlock('wrong') }.to raise_error
    end

    it 'should have accounts' do
      wallet = app.wallets.create('name', 'p2')
      account = wallet.accounts['default']
      expect(account.respond_to?(:pay)).to eq true
      expect(wallet.backup_key).to_not be_nil
    end

    it 'should view users' do
      size = app.users.size
      _, user = identify_auth_user
      expect(app.users.size).to eq size + 1
      expect(app.user_from_key(user.key).key).to eq user.key
    end
  end
end
