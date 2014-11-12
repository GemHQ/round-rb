class Round::Application < Round::Base

  def wallets
    @resource.context.set_token(@resource.url, @resource.api_token)
    @wallets ||= Round::WalletCollection.new(resource: @resource.wallets)
    @wallets
  end

  def rules
    @rules ||= Round::Rules.new(@resource.rules)
  end

end
