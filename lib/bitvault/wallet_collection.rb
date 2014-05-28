class BitVault::WalletCollection < BitVault::Collection

  def collection_type
    BitVault::Wallet
  end

  def create(options = {})
    raise ArgumentError unless options[:passphrase] and options[:name]
    wallet = BitVault::Wallet.new(resource: self.create_wallet_resource(options[:passphrase], options[:name]))
    @collection << wallet
    wallet
  end

  def create_wallet_resource(passphrase, name)
    new_wallet = BitVault::Bitcoin::MultiWallet.generate [:primary, :backup]
    primary_seed = new_wallet.trees[:primary].to_serialized_address(:private)

    ## Encrypt the primary seed using a passphrase-derived key
    encrypted_seed = BitVault::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)

    self.resource.create(
      name: "my favorite wallet",
      network: "bitcoin_testnet",
      backup_address: new_wallet.trees[:backup].to_serialized_address,
      primary_address: new_wallet.trees[:primary].to_serialized_address,
      primary_seed: encrypted_seed
    )
  end

end