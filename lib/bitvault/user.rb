class BitVault::User
  extend Forwardable

  def_delegators :@resource, :update

  attr_reader :resource

  def initialize(options = {})
    @resource = options[:resource]
  end

end