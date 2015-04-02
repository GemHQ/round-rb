module Round
  class Transaction < Round::Base

    def sign(wallet)
      raise 'transaction is already signed' unless @resource.status == 'unsigned'
      raise 'a wallet is required to sign a transaction' unless wallet

      transaction = CoinOp::Bit::Transaction.data(@resource)
      raise "bad change address" unless wallet.valid_output?(transaction.outputs.last)
      
      @resource = @resource.sign(
        transaction_hash: transaction.hex_hash,
        inputs: wallet.signatures(transaction)
      )
      self
    end

    def transaction_hash
      @resource[:hash]
    end

    def self.hash_identifier
      "hash"
    end

  end

  class TransactionCollection < Round::Collection

    def content_type
      Round::Transaction
    end

    def create(payees, confirmations = 6)
      raise 'Must have list of payees' unless payees

      payment_resource = @resource.payments.create(
        { confirmations: confirmations }.merge(self.outputs_from_payees(payees))
      )

      Round::Transaction.new(resource: payment_resource, client: @client)
    end

    def outputs_from_payees(payees)
      raise ArgumentError, 'Payees must be an array' unless payees.is_a?(Array)
      outputs = payees.map do |payee|
        raise 'Bad output, no amount' unless payee[:amount]
        raise 'Bad output, no address' unless payee[:address]
        {
          amount: payee[:amount],
          payee: { address: payee[:address] }
        }
      end
      { outputs: outputs }
    end

  end
end