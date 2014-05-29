class BitVault::Collection < BitVault::Base
  def initialize(options = {})
    super(options)
    @collection = []
    self.populate_array
  end

  def populate_array
    @resource.list.each do |resource|
      @collection << self.collection_type.new(resource: resource)
    end
  end

  def collection_type
    raise 'Must implement collection_type in child class of BitVault::Collection'
  end

  private

  def method_missing(method, *args, &block)
    @collection.send(method, *args, &block) if @collection.methods.include? method
  end
end
