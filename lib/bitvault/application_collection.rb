class BitVault::ApplicationCollection < BitVault::Collection

  def create(options = {})
    app_resource = @resource.create(options)
    app = BitVault::Application.new(resource: app_resource)
    self.add(app)
    app
  end

  def content_type
    BitVault::Application
  end

end