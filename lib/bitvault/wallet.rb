class BitVault::Wallet < BitVault::Base
  def_delegators :@resource, :name, :network, :cosigner_public_seed, 
    :backup_public_seed, :primary_public_seed, :primary_private_seed

  attr_accessor :multiwallet

  def accounts
    @accounts ||= BitVault::AccountCollection.new(resource: @resource.accounts, wallet: self)
    @accounts
  end

  def unlock(passphrase)
    primary_seed = CoinOp::Crypto::PassphraseBox.decrypt(passphrase, @resource.primary_private_seed)
    @multiwallet = CoinOp::Bit::MultiWallet.new(
      private: {
        primary: primary_seed
      },
      public: {
        cosigner: @resource.cosigner_public_seed,
        backup: @resource.backup_public_seed
      }
    )
  end

  def transfer(options = {})
    raise ArgumentError, 'Must specify a source account' unless options[:source]
    raise ArgumentError, 'Must specify a destination account' unless options[:destination]
    raise ArgumentError, 'Must specify an amount' unless options[:amount]
    raise 'Wallet must be unlocked before you can create a transfer' unless @multiwallet

    unsigned_transfer = @resource.transfers.create(
      value: options[:amount],
      source: options[:source].url,
      destination: options[:destination].url)
    transaction = CoinOp::Bit::Transaction.data(unsigned_transfer)
    signed_transfer = unsigned_transfer.sign(
      transaction_hash: transaction.base58_hash,
      inputs: @multiwallet.signatures(transaction))
    BitVault::Transaction.new(resource: signed_transfer)
  end

end