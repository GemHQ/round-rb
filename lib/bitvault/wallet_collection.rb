class BitVault::WalletCollection < BitVault::Collection

  def content_type
    BitVault::Wallet
  end

  def create(options = {})
    raise ArgumentError, "Name and passphrase are required" unless options[:passphrase] and options[:name]
    network = options[:network] || "bitcoin_testnet"
    multiwallet, wallet_resource = self.generate_wallet(options[:passphrase], options[:name], network)
    wallet = BitVault::Wallet.new(resource: wallet_resource)
    wallet.multiwallet = multiwallet
    self.add(wallet)
    wallet
  end

  def generate_wallet(passphrase, name, network)
    multiwallet = CoinOp::Bit::MultiWallet.generate [:primary, :backup]
    primary_seed = multiwallet.trees[:primary].to_serialized_address(:private)

    ## Encrypt the primary seed using a passphrase-derived key
    encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)

    wallet_resource = @resource.create(
      name: name,
      network: network,
      backup_public_seed: multiwallet.trees[:backup].to_serialized_address,
      primary_public_seed: multiwallet.trees[:primary].to_serialized_address,
      primary_private_seed: encrypted_seed
    )

    [multiwallet, wallet_resource]
  end

end