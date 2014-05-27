class BitVault::ApplicationCollection < BitVault::Base

  def initialize(options = {})
    super(options)
    @collection = []
    self.populate_array
  end

  def populate_array
    @resource.list.each do |app|
      @collection << BitVault::Application.new(resource: app)
    end
  end

  def create(options = {})
    app_resource = @resource.create(options)
    app = BitVault::Application.new(resource: app_resource)
    @collection << app
    app
  end

  private

  def method_missing(method, *args, &block)
    @collection.send(method, *args, &block)
  end
end