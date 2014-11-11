require 'spec_helper'

describe Round::PaymentGenerator do
  
  let(:unsigned_resource) { double('payment_resource') }
  let(:payments_resource) { double('payments_resource', create: unsigned_resource) }
  let(:payment_generator) { Round::PaymentGenerator.new(resource: payments_resource) }

  describe '#unsigned' do
    let(:payees) { [double('payee')] }
    let(:outputs) { double('outputs') }
    let(:unsigned) { payment_generator.unsigned(payees) }

    before(:each) {
      allow(payment_generator).to receive(:outputs_from_payees) { outputs }
    }

    it 'raises error without payees' do
      expect { payment_generator.unsigned(nil) }.to raise_error(RuntimeError)
    end

    it 'returns a Payment model' do
      expect(unsigned).to be_a_kind_of(Round::Payment)
      expect(unsigned.resource).to eql(unsigned_resource)
    end

    it 'delegates to the resource' do
      expect(payment_generator.resource).to receive(:create).with(outputs)
      unsigned
    end
  end

  describe '#outputs_from_payees' do
    context 'anything but an array is passed' do
      it 'raises an error' do
        expect{ payment_generator.outputs_from_payees(Object.new) }.to raise_error(ArgumentError)
      end
    end

    context 'with missing address' do
      it 'raises an error' do
        expect { payment_generator.outputs_from_payees([ {amount: 10_000} ]) }.to raise_error
      end
    end

    context 'with missing amount' do
      it 'raises an error' do
        expect { payment_generator.outputs_from_payees([ {address: 'abcdef123456'} ]) }.to raise_error
      end
    end

    context 'with correct input' do
      let(:outputs) { payment_generator.outputs_from_payees([ {address: 'abcdef123456', amount: 10_000} ]) }
      it 'returns a Hash' do
        expect(outputs).to be_a_kind_of(Hash)
      end

      it 'has a root node of outputs' do
        expect(outputs).to include(:outputs)
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

end