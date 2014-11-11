require 'spec_helper'

describe Round::Payment do
  let(:signed_payment) { double('signed_payment') }
  let(:unsigned_payment) { double('unsigned_payment', sign: signed_payment) }
  let(:payment) { Round::Payment.new(resource: unsigned_payment) }

  describe '#sign' do 
    let(:transaction) { double('transaction', hex_hash: hex_hash, outputs: []) }
    let(:signatures) { double('signatures') }
    let(:hex_hash) { 'abcdef123456' }
    let(:wallet) { double('wallet', signatures: signatures, valid_output?: true) }

    before(:each) {
      allow(CoinOp::Bit::Transaction).to receive(:data) { transaction }
    }

    context 'with invalid change address' do
      before(:each) { 
        allow(wallet).to receive(:valid_output?).and_return(false) 
      }
      
      it 'raises an error' do
        expect { payment.sign(wallet) }.to raise_error(RuntimeError)
      end
    end

    context 'with no wallet' do
      it 'raises an error' do
        expect { payment.sign(nil) }.to raise_error(RuntimeError)
      end
    end

    context 'with valid inputs' do
      it 'calls sign on the resource' do
        expect(unsigned_payment).to receive(:sign).with(
          transaction_hash: hex_hash,
          inputs: signatures)
        payment.sign(wallet)
      end

      it 'sets the resource to the signed_payment' do
        payment.sign(wallet)
        expect(payment.resource).to eql(signed_payment)
      end
    end

  end

  describe 'delegate methods' do
    [:status].each do |method|
      it "delegates #{method} to the resource" do
        expect(payment.resource).to receive(method)
        payment.send(method)
      end
    end
  end
end