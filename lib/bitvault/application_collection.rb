class BitVault::ApplicationCollection < BitVault::Collection

  def create(options = {})
    app_resource = @resource.create(options)
    app = BitVault::Application.new(resource: app_resource)
    @collection << app
    app
  end

  def content_type
    BitVault::Application
  end

end