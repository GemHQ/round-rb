class Round::UserCollection < Round::Collection

  def create(email, passphrase)
    multiwallet = CoinOp::Bit::MultiWallet.generate([:primary, :backup])
    network = "bitcoin_testnet"
    primary_seed = multiwallet.trees[:primary].to_serialized_address(:private)
    encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)
    wallet = {
      network: network,
      backup_public_seed: multiwallet.trees[:backup].to_serialized_address,
      primary_public_seed: multiwallet.trees[:primary].to_serialized_address,
      primary_private_seed: encrypted_seed
    }
    params = {
      email: email,
      wallet: wallet
    }
    user_resource = @resource.create(params)
    return multiwallet, Round::User.new(resource: user_resource)
  end

end
