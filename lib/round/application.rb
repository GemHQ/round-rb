class Round::Application < Round::Base
  def_delegators :@resource, :name, :callback_url, :update, :api_token

  def wallets
    @resource.context.set_token(@resource.url, @resource.api_token)
    @wallets ||= Round::WalletCollection.new(resource: @resource.wallets)
    @wallets
  end

  def rules
    @rules ||= Round::Rules.new(@resource.rules)
  end

end
