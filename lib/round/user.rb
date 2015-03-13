module Round
  class User < Round::Base

    def wallets
      Round::WalletCollection.new(resource: @resource.wallets, client: @client)
    end

    def default_wallet
      Wallet.new(resource: @resource.default_wallet, client: @client)
    end

  end

  class UserCollection < Round::Collection

    def create(email, passphrase)
      multiwallet = CoinOp::Bit::MultiWallet.generate([:primary, :backup], @client.network)
      primary_seed = multiwallet.trees[:primary].to_serialized_address(:private)
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
      return multiwallet.trees[:backup].to_serialized_address(:private),
        Round::User.new(resource: user_resource, client: @client)
    end

  end
end
