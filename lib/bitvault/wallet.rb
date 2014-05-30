class BitVault::Wallet < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :name

  def accounts
    @accounts ||= BitVault::AccountCollection.new(resource: @resource.accounts, wallet: self)
    @accounts
  end

  def unlock(passphrase)
    primary_seed = BitVault::Crypto::PassphraseBox.decrypt(passphrase, @resource.primary_seed)
    @multiwallet = MultiWallet.new(
      private: {
        primary: primary_seed
      },
      public: {
        cosigner: @resource.cosigner_address,
        backup: @resource.backup_address
      }
    )
  end

end