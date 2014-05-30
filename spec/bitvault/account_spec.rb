require 'spec_helper'

describe BitVault::Account, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:wallet) { authed_client.user.applications[0].wallets[0] }
  let(:account) { BitVault::Account.new(resource: wallet.accounts[0].resource, wallet: wallet) }

  describe '#initialize' do
    it 'sets the wallet attribute' do
      expect(account.wallet).to eql(wallet)
    end
  end

  describe '#pay' do
    it 'raises an error with no payees' do
      expect{ account.pay }.to raise_error(ArgumentError)
    end

    it 'raises an error when incorrect object passed' do
      expect{ account.pay(payees: Object.new) }.to raise_error(ArgumentError)
    end
  end
end