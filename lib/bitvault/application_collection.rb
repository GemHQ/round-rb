class BitVault::ApplicationCollection < BitVault::Collection

  def create(options = {})
    app_resource = @resource.create(options)
    app = self.collection_type.new(resource: app_resource)
    @collection << app
    app
  end

  def collection_type
    BitVault::Application
  end

end