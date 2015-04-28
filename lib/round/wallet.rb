module Round
  class Wallet < Round::Base

    attr_reader :multiwallet, :application

    def initialize(options = {})
      @multiwallet = options[:multiwallet]
      @application = options[:application]
      super(options)
    end

    def unlock(passphrase)
      primary_seed = CoinOp::Crypto::PassphraseBox.decrypt(passphrase, @resource.primary_private_seed)
      primary_master = MoneyTree::Master.new(seed_hex: primary_seed)
      @multiwallet = CoinOp::Bit::MultiWallet.new(
        private: {
          primary: primary_master
        },
        public: {
          cosigner: @resource.cosigner_public_seed,
          backup: @resource.backup_public_seed
        }
      )
    end

    def backup_key
      @multiwallet.private_seed(:backup) 
    end

    def accounts
      Round::AccountCollection.new(resource: @resource.accounts, wallet: self)
    end

    def self.hash_identifier
      'name'
    end
  end

  class WalletCollection < Round::Collection

    def initialize(options={}, &block)
      super
      @parent = options[:parent]
    end

    def content_type
      Round::Wallet
    end

    def create(name, passphrase, network: 'bitcoin_testnet',
               multiwallet: CoinOp::Bit::MultiWallet.generate([:primary, :backup]))
      wallet_resource = create_wallet_resource(multiwallet, passphrase, name)
      multiwallet.import(
        cosigner: wallet_resource.cosigner_public_seed,
      )
      wallet = Round::Wallet.new(resource: wallet_resource, multiwallet: multiwallet, application: @application)
      add(wallet)
      wallet
    end

    def create_wallet_resource(multiwallet, passphrase, name)
      primary_seed = CoinOp::Encodings.hex(multiwallet.trees[:primary].seed)
      ## Encrypt the primary seed using a passphrase-derived key
      encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)

      @resource.create(
        name: name,
        backup_public_seed: multiwallet.trees[:backup].to_serialized_address,
        primary_public_seed: multiwallet.trees[:primary].to_serialized_address,
        primary_private_seed: encrypted_seed
      )
    end

  end
end
