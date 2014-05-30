class BitVault::WalletCollection < BitVault::Collection

  def collection_type
    BitVault::Wallet
  end

  def create(options = {})
    raise ArgumentError, "Name and passphrase are required" unless options[:passphrase] and options[:name]
    network = options[:network] || "bitcoin_testnet"
    wallet = BitVault::Wallet.new(resource: self.create_wallet_resource(options[:passphrase], options[:name], network))
    @collection << wallet
    wallet
  end

  def create_wallet_resource(passphrase, name, network)
    new_wallet = BitVault::Bitcoin::MultiWallet.generate [:primary, :backup]
    primary_seed = new_wallet.trees[:primary].to_serialized_address(:private)

    ## Encrypt the primary seed using a passphrase-derived key
    encrypted_seed = BitVault::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)

    @resource.create(
      name: name,
      network: network,
      backup_public_seed: new_wallet.trees[:backup].to_serialized_address,
      primary_public_seed: new_wallet.trees[:primary].to_serialized_address,
      primary_private_seed: encrypted_seed
    )
  end

end