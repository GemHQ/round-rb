module Round
  class Transaction < Round::Base

    def sign(wallet, network:)
      raise 'transaction is already signed' unless @resource['status'] == 'unsigned'
      raise 'a wallet is required to sign a transaction' unless wallet

      transaction = CoinOp::Bit::Transaction.data(@resource, network: network)
      binding.pry
      raise 'bad change address' unless wallet.valid_output?(transaction.outputs.last)
      
      @resource = @resource.update( 
         signatures: {
           transaction_hash: transaction.hex_hash,
           inputs: wallet.signatures(transaction)
         }
      )
      self
    end

    def transaction_hash
      @resource[:hash]
    end

    def self.hash_identifier
      'hash'
    end

  end

  class TransactionCollection < Round::Collection

    def content_type
      Round::Transaction
    end

    def create(payees, confirmations = 6, redirect_uri: nil)
      raise 'Must have list of payees' unless payees

      payment_resource = @resource.create(
        utxo_confirmations: confirmations,
        payees: payees,
        redirect_uri: redirect_uri
      )

      Round::Transaction.new(resource: payment_resource, client: @client)
    end

  end
end
