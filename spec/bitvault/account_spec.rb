require 'spec_helper'

describe BitVault::Account, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:wallet) { authed_client.user.applications[0].wallets[0] }
  let(:passphrase) { 'very insecure' }
  let(:account) { BitVault::Account.new(resource: wallet.accounts[0].resource, wallet: wallet) }

  describe '#initialize' do
    it 'sets the wallet attribute' do
      expect(account.wallet).to eql(wallet)
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
        expect{ account.pay(payees: []) }.to raise_error
      end
    end

    context 'when a transaction is attempted with an unlocked wallet' do
      before { 
        wallet.unlock(passphrase) 
        account.resource.payments.stub(:create).and_return({})
        account.stub(:outputs_from_payees).and_return({})
        account.stub(:sign_payment).and_return({})
        CoinOp::Bit::Transaction.stub(:data).and_return({})
      }

      it 'returns a Payment model' do
        expect(account.pay(payees: [ {address: 'abcdef123456', amount: 10_000} ]))
          .to be_a_kind_of(BitVault::Transaction)
      end
    end
  end

  describe '#outputs_from_payees' do
    context 'anything but an array is passed' do
      it 'raises an error' do
        expect{ account.outputs_from_payees(Object.new) }.to raise_error(ArgumentError)
      end
    end

    context 'with missing address' do
      it 'raises an error' do
        expect { account.outputs_from_payees([ {amount: 10_000} ]) }.to raise_error
      end
    end

    context 'with missing amount' do
      it 'raises an error' do
        expect { account.outputs_from_payees([ {address: 'abcdef123456'} ]) }.to raise_error
      end
    end

    context 'with correct input' do
      let(:outputs) { account.outputs_from_payees([ {address: 'abcdef123456', amount: 10_000} ]) }
      it 'returns a Hash' do
        expect(outputs).to be_a_kind_of(Hash)
      end

      it 'has a root node of outputs' do
        expect(outputs.has_key?(:outputs)).to be_true
      end

      it 'has the correct number of entries' do
        expect(outputs[:outputs].count).to eql(1)
      end

      it 'has the correct values and structure' do
        expect(outputs[:outputs].first[:amount]).to eql(10_000)
        expect(outputs[:outputs].first[:payee][:address]).to eql('abcdef123456')
      end
    end
  end

  describe '#sign_payment' do 
    let(:transaction) { double('transaction') }
    let(:unsigned_payment) { double('unsigned_payment') }
    let(:signed_payment) { double('signed_payment') }
    let(:signatures) { double('signatures') }
    let(:base58_hash) { 'abcdef123456' }
    before(:each) { wallet.unlock(passphrase) }

    context 'with invalid change address' do
      before(:each) { account.wallet.multiwallet.stub(:valid_output?).and_return(false) }
      it 'raises an error' do
        expect { account.sign_payment(unsigned_payment, transaction) }.to raise_error
      end
    end

    context 'with no transaction' do
      it 'raises and error' do
        expect { account.sign_payment(unsigned_payment, nil) }.to raise_error(ArgumentError)
      end
    end

    context 'with no unsigned_payment' do
      it 'raises and error' do
        expect { account.sign_payment(nil, transaction) }.to raise_error(ArgumentError)
      end
    end

    context 'with valid inputs' do
      before(:each) {
        allow(unsigned_payment).to receive(:sign) { signed_payment }
        allow(transaction).to receive(:base58_hash) { base58_hash }
        allow(transaction).to receive(:outputs) { [] }
        account.wallet.multiwallet.stub(:signatures).and_return(signatures)
        account.wallet.multiwallet.stub(:valid_output?).and_return(true)
      }
      it 'calls sign on the unsigned transaction' do
        unsigned_payment.should receive(:sign).with(
          transaction_hash: base58_hash,
          inputs: signatures)
        account.sign_payment(unsigned_payment, transaction)
      end

      it 'returns the signed payment' do
        expect(account.sign_payment(unsigned_payment, transaction)).to eql(signed_payment)
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
end