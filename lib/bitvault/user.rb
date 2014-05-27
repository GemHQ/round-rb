class BitVault::User < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :update

  def initialize(options = {})
    super(options)
  end

  def applications
  	@applications = BitVault::ApplicationCollection.new(resource: @resource.applications)
  	@applications
  end

end