module Round
  class Developer < Round::Base

    def applications(options = {})
      @applications ||= Round::ApplicationCollection.new(resource: @resource.applications, client: @client)
    end

  end

  class DeveloperCollection < Round::Base

    def create(email, pubkey)
      raise ArgumentError, 'Email and pubkey is required' unless email and pubkey
      user_resource = @resource.create(email: email, pubkey: pubkey)
      Round::Developer.new(resource: user_resource)
    end

  end
end