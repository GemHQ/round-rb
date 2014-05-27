class BitVault::User
  extend Forwardable

  def_delegators :@resource, :update

  attr_reader :resource

  def initialize(options = {})
    @resource = options[:resource]
  end

  def applications
  	@applications = BitVault::ApplicationCollection.new(resource: @resource.applications)
  	@applications
  end

end