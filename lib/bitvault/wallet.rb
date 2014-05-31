class BitVault::Wallet < BitVault::Base
  extend Forwardable
  def_delegators :@resource, :name

  attr_accessor :multiwallet

  def accounts
    @accounts ||= BitVault::AccountCollection.new(resource: @resource.accounts, wallet: self)
    @accounts
  end

  def unlock(passphrase)
    primary_seed = BitVault::Crypto::PassphraseBox.decrypt(passphrase, @resource.primary_private_seed)
    @multiwallet = BitVault::Bitcoin::MultiWallet.new(
      private: {
        primary: primary_seed
      },
      public: {
        cosigner: @resource.cosigner_public_seed,
        backup: @resource.backup_public_seed
      }
    )
  end

end