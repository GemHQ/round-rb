class BitVault::Collection < BitVault::Base
  include Enumerable

  def_delegators :@collection, :[]

  attr_accessor :collection

  def each(&block)
    @collection.each(&block)
  end

  def initialize(options = {})
    super(options)
    if self.collection_type == Array
      @collection = []
    elsif self.collection_type == Hash
      @collection = {}
    end
    options.delete(:resource)
    self.populate_data(options)
  end

  def populate_data(options)
    resource.list.each do |resource|
      content = self.content_type.new(options.merge(resource: resource))
      self.add(content)
    end
  end

  def add(content)
    if self.collection_type == Array
      @collection << content
    elsif self.collection_type == Hash
      @collection[content.send(self.content_key)] = content
    end
  end

  def collection_type
    Hash
  end

  def content_type
    BitVault::Base
  end

  def content_key
    :name
  end
  
end
