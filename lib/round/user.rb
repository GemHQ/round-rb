module Round
  class User < Round::Base

    def wallets
      Round::WalletCollection.new(resource: @resource.wallets, client: @client)
    end

    def default_wallet
      Wallet.new(resource: @resource.default_wallet, client: @client)
    end

  end
end
