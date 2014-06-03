class BitVault::User < BitVault::Base
  def_delegators :@resource, :update, :email, :first_name, :last_name

  def applications(options = {})
  	@applications = BitVault::ApplicationCollection.new(resource: @resource.applications) if !@applications || options[:refresh]
  	@applications
  end

end