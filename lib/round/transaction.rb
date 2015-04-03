module Round
  class Transaction < Round::Base

    def sign(wallet)
      raise 'transaction is already signed' unless @resource['status'] == 'unsigned'
      raise 'a wallet is required to sign a transaction' unless wallet

      transaction = CoinOp::Bit::Transaction.data(@resource)
      raise "bad change address" unless wallet.valid_output?(transaction.outputs.last)
      
      @resource = @resource.update( signatures: {
          transaction_hash: transaction.hex_hash,
          inputs: wallet.signatures(transaction)
        }
      )
      @resource.mfa_uri, self
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

      payment_resource = @resource.create(
        { utxo_confirmations: confirmations, payees: payees }
      )

      Round::Transaction.new(resource: payment_resource, client: @client)
    end

  end
end