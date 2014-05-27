class BitVault::ApplicationCollection < BitVault::Base
  extend Forwardable

  def_delegators :@collection, :each, :count, :map

  def initialize(options = {})
    super(options)
    self.populate_array
  end

  def populate_array
    @collection = []
    @resource.list.each do |app|
      @collection << BitVault::Application.new(resource: app)
    end
  end

  def create(options = {})
    app = @resource.create(options)
    @collection << BitVault::Application.new(resource: app)
  end
end