class BitVault::Application < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :name, :callback_url, :update

  def initialize(options = {})
    super(options)
  end

  def wallets
    
  end

end