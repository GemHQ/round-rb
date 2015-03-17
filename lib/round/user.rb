module Round
  class User < Round::Base
    association :wallets, "Round::WalletCollection"
    association :default_wallet, "Round::Wallet"

    def self.hash_identifier
      "email"
    end
  end

  class UserCollection < Round::Collection

    def content_type
      Round::User
    end

    def create(email, passphrase)
      multiwallet = CoinOp::Bit::MultiWallet.generate([:primary, :backup], @client.network)
      primary_seed = CoinOp::Encodings.hex(multiwallet.trees[:primary].seed)
      encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)
      wallet = {
        name: "default",
        network: @client.network,
        backup_public_seed: multiwallet.trees[:backup].to_serialized_address,
        primary_public_seed: multiwallet.trees[:primary].to_serialized_address,
        primary_private_seed: encrypted_seed
      }
      params = {
        email: email,
        default_wallet: wallet
      }
      user_resource = @resource.create(params)
      backup_seed = CoinOp::Encodings.hex(multiwallet.trees[:backup].seed)
      return backup_seed,
        Round::User.new(resource: user_resource, client: @client)
    end

  end
end
