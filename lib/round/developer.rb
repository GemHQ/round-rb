class Round::Developer < Round::Base

  def applications(options = {})
    @applications ||= Round::ApplicationCollection.new(resource: @resource.applications)
  end

end