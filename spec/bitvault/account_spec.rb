require 'spec_helper'

describe BitVault::Account, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:wallet) { authed_client.user.applications['bitcoin_app'].wallets['my funds'] }
  let(:passphrase) { 'very insecure' }
  let(:account) { BitVault::Account.new(resource: wallet.accounts['office supplies'].resource, wallet: wallet) }

  describe '#initialize' do
    it 'sets the wallet attribute' do
      expect(account.wallet).to eql(wallet)
    end
  end

  describe 'delegated methods' do
    [:name, :path, :balance, :pending_balance].each do |method|
      it "delegates #{method} to resource" do
        account.resource.should_receive method
        account.send(method)
      end
    end
  end

  describe '#pay' do
    context 'when invalid parameters are passed' do
      it 'raises an error with no payees' do
        expect{ account.pay }.to raise_error(ArgumentError)
      end
    end

    context 'when a transaction is attempted with a locked wallet' do
      it 'raises an error when the wallet is locked' do
        expect{ account.pay([]) }.to raise_error
      end
    end

    context 'when a transaction is attempted with an unlocked wallet' do
      let(:payment_resource) { double('payment_resource', sign: nil) }
      let(:payment) { account.pay([ {address: 'abcdef123456', amount: 10_000} ]) }
      before(:each) { 
        wallet.unlock(passphrase) 
        account.payments.stub(:unsigned).and_return(payment_resource)
      }

      it 'returns a Payment model' do
        account.payments.should_receive(:unsigned)
        payment_resource.should_receive(:sign).with(account.wallet.multiwallet)
        expect(payment).to be_a_kind_of(BitVault::Payment)
        expect(payment.resource).to eql(payment_resource)
      end
    end
  end

  describe '#addresses' do
    before(:each) { 
      account.resource.addresses.stub(:list).and_return([])
    }

    it 'returns an AddressCollection' do
      expect(account.addresses).to be_a_kind_of(BitVault::AddressCollection)
    end

    it 'only fetches once' do
      account.resource.addresses.should_receive(:list).once
      account.addresses
      account.addresses
    end
  end

  describe '#transactions' do
    before(:each) { 
      account.resource.stub(:transactions).and_return(double('transactions_resource', list: []))
    }

    it 'returns a TransactionCollection' do
      expect(account.transactions).to be_a_kind_of(BitVault::TransactionCollection)
    end
  end

  describe '#payments' do
    it 'returns a PaymentGenerator' do
      expect(account.payments).to be_a_kind_of(BitVault::PaymentGenerator)
    end
  end

end