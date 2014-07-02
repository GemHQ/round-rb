require 'spec_helper'

describe BitVault::Account do
  let(:multiwallet) { double('multiwallet') }
  let(:unlocked_wallet) { double('wallet', multiwallet: multiwallet) }
  let(:locked_wallet) { double('wallet', multiwallet: nil) }
  let(:passphrase) { 'very insecure' }
  let(:payments_resource) { double('payments_resource') }
  let(:addresses_resource) { double('addresses_resource') }
  let(:account_resource) { double('account_resource', payments: payments_resource, addresses: addresses_resource) }
  let(:account) { BitVault::Account.new(resource: account_resource, wallet: locked_wallet) }


  describe '#initialize' do
    it 'sets the wallet attribute' do
      expect(account.wallet).to eql(locked_wallet)
    end
  end

  describe 'delegated methods' do
    [:name, :path, :balance, :pending_balance].each do |method|
      it "delegates #{method} to resource" do
        expect(account.resource).to receive(method)
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
      let(:account) { BitVault::Account.new(resource: account_resource, wallet: unlocked_wallet) }
      before(:each) { 
        allow(account.payments).to receive(:unsigned).and_return(payment_resource)
      }

      it 'returns a Payment model' do
        expect(account.payments).to receive(:unsigned)
        expect(payment_resource).to receive(:sign).with(account.wallet.multiwallet)
        expect(payment).to eql(payment_resource)
      end
    end
  end

  describe '#addresses' do
    before(:each) { 
      allow(account.resource.addresses).to receive(:list).and_return([])
    }

    it 'returns an AddressCollection' do
      expect(account.addresses).to be_a_kind_of(BitVault::AddressCollection)
    end

    it 'only fetches once' do
      expect(account.resource.addresses).to receive(:list).once
      account.addresses
      account.addresses
    end
  end

  describe '#transactions' do
    before(:each) { 
      allow(account.resource).to receive(:transactions).and_return(double('transactions_resource', list: []))
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