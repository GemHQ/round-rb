module Round
  class Device < Base

  end

  class DeviceCollection < Collection
    def create(name)
      resource = @resource.create(name: name)
      Round::Device.new(resource: resource, client: @client)
    end
  end
end