class BitVault::Application < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :name, :callback_url, :update

  def initialize(options = {})
    super(options)
  end

  def wallets
    @resource.context.set_token(@resource.api_token)
    @wallets ||= BitVault::WalletCollection.new(resource: @resource.wallets)
    @wallets
  end
end