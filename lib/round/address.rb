module Round
  class Address < Round::Base
    
  end

  class AddressCollection < Round::Collection

    def content_type
      Round::Address
    end

    def create
      resource = @resource.create
      address = Round::Address.new(resource: resource)
      self.add(address)
      address
    end
  end
end