class BitVault::User < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :update

  def initialize(options = {})
    super(options)
  end

  def applications(options = {})
  	@applications = BitVault::ApplicationCollection.new(resource: @resource.applications) if !@applications || options[:refresh]
  	@applications
  end

end