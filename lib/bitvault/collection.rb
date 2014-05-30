class BitVault::Collection < BitVault::Base
  def initialize(options = {})
    super(options)
    @collection = []
    options.delete(:resource)
    self.populate_array(options)
  end

  def populate_array(options)
    @resource.list.each do |resource|
      options.merge!(resource: resource)
      @collection << self.collection_type.new(options)
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
