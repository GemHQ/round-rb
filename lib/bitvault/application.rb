class BitVault::Application < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :name, :callback_url

  def initialize(options = {})
    super(options)
  end
end