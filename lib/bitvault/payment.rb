class BitVault::Payment < BitVault::Base

  def_delegators :@resource, :hash, :status

  def sign(wallet)
    raise 'a wallet is required to sign a transaction' unless wallet

    transaction = CoinOp::Bit::Transaction.data(@resource)
    raise "bad change address" unless wallet.valid_output?(transaction.outputs.last)
    
    @resource = @resource.sign(
      transaction_hash: transaction.hex_hash,
      inputs: wallet.signatures(transaction)
    )
  end

end