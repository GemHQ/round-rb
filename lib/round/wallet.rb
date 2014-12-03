module Round
  class Wallet < Round::Base

    attr_accessor :multiwallet

    def initialize(options = {})
      @multiwallet = options[:multiwallet]
      super(options)
    end

    def accounts
      @accounts ||= Round::AccountCollection.new(
        resource: @resource.accounts, wallet: self
      )
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

  end
end