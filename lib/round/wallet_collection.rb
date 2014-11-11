class Round::WalletCollection < Round::Collection

  def content_type
    Round::Wallet
  end

  def create(options = {})
    raise ArgumentError, "Name and passphrase are required" unless options[:passphrase] and options[:name]

    multiwallet = options[:multiwallet] || CoinOp::Bit::MultiWallet.generate([:primary, :backup])
    network = options[:network] || "bitcoin_testnet"
    wallet_resource = self.create_wallet_resource(multiwallet, options[:passphrase], options[:name], network)

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