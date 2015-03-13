module Round
  class Developer < Round::Base
    association :applications, "Round::ApplicationCollection"

    def self.hash_identifier
      "email"
    end 
  end

  class DeveloperCollection < Round::Base
    def content_type
      Round::Developer
    end

    def create(email, pubkey)
      raise ArgumentError, 'Email and pubkey is required' unless email and pubkey
      user_resource = @resource.create(email: email, pubkey: pubkey)
      Round::Developer.new(resource: user_resource)
    end

  end
end