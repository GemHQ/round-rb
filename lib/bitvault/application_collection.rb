class BitVault::ApplicationCollection < BitVault::Base
  extend Forwardable

  def_delegators :@collection, :each, :count, :map

  def initialize(options = {})
    super(options)
    @collection = []
    self.populate_array
  end

  def populate_array
    @resource.each do |app|
      @collection << BitVault::Application.new(resource: app)
    end
  end

  def create(options = {})
    app_resource = @resource.create(options)
    app = BitVault::Application.new(resource: app_resource)
    @collection << app
    app
  end
end