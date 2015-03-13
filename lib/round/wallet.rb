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

  class WalletCollection < Round::Collection

    def content_type
      Round::Wallet
    end

    def create(name, passphrase, options = {})

      multiwallet = options[:multiwallet] || CoinOp::Bit::MultiWallet.generate([:primary, :backup])
      network = options[:network] || "bitcoin_testnet"
      wallet_resource = self.create_wallet_resource(multiwallet, passphrase, name, network)

      wallet = Round::Wallet.new(resource: wallet_resource, multiwallet: multiwallet)
      self.add(wallet)
      
      wallet
    end

    def create_wallet_resource(multiwallet, passphrase, name, network)
      primary_seed = multiwallet.trees[:primary].to_serialized_address(:private)

      ## Encrypt the primary seed using a passphrase-derived key
      encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)

      @resource.create(
        name: name,
        network: network,
        backup_public_seed: multiwallet.trees[:backup].to_serialized_address,
        primary_public_seed: multiwallet.trees[:primary].to_serialized_address,
        primary_private_seed: encrypted_seed
      )
    end

  end
end