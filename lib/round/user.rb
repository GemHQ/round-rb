class Round::User < Round::Base

  attr_reader :wallet

  def initialize(options = {})
    super
    @wallet = options[:wallet]
  end

  def wallets
    @wallets ||= WalletCollection.new(resource: @resource.wallets)
  end

end