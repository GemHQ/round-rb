module Round
  class Developer < Round::Base

    def applications(options = {})
      @applications ||= Round::ApplicationCollection.new(resource: @resource.applications, client: @client)
    end

  end
end