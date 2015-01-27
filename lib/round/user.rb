module Round
  class User < Round::Base
    include Round::Helpers

    def wallets
      @wallets ||= Round::WalletCollection.new(resource: @resource.wallets)
    end

    def default_wallet
      Wallet.new(resource: @resource.default_wallet, client: @client)
    end

  end
end
