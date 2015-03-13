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
    end

    def transaction_hash
      @resource[:hash]
    end

  end

  class TransactionCollection < Round::Collection

    def content_type
      Round::Transaction
    end

  end
end