class BitVault::WalletCollection < BitVault::Collection

  def collection_type
    BitVault::Wallet
  end

  def create(options = {})
    raise ArgumentError unless options[:passphrase] and options[:name]
    options.merge!(resource: {})
    wallet = BitVault::Wallet.new(options)
    @collection << wallet
    wallet
  end

end