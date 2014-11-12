class Round::User < Round::Base

  def applications(options = {})
  	@applications = Round::ApplicationCollection.new(resource: @resource.applications) if !@applications || options[:refresh]
  	@applications
  end

end