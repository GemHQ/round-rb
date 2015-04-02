module Round
  class Device < Base
    
  end

  class DeviceCollection < BaseCollection
    def create(name)
      resource = @resource.create(name: name)
      Round::Device.new(resource: resource, client: @client)
    end
  end
end