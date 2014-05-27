class BitVault::ApplicationCollection
  extend Forwardable

  def_delegators :@collection, :each, :count, :map

  attr_reader :resource

  def initialize(options = {})
    @resource = options[:resource]
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