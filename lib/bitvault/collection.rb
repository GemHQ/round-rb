class BitVault::Collection < BitVault::Base
  include Enumerable

  def_delegators :@collection, :[]

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
    @resource.list.each do |resource|
      options.merge!(resource: resource)
      content = self.content_type.new(options)
      self.add(content)
    end
  end

  def add(content)
    if self.collection_type == Array
      @collection << content
    elsif self.collection_type == Hash
      key = self.content_key || :name
      @collection[content.send(key)] = content
    end
  end

  def collection_type
    Hash
  end

  def content_type
    raise 'Must implement content_type in child class of BitVault::Collection'
  end

  def content_key

  end
  
end
