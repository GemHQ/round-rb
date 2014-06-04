class BitVault::Collection < BitVault::Base
  def_delegators :@collection, :each, :count, :[], :first, :last

  def initialize(options = {})
    super(options)
    if collection_type == Array
      @collection = []
    elsif collection_type == Hash
      @collection = {}
    end
    options.delete(:resource)
    self.populate_data(options)
  end

  def populate_data(options)
    @resource.list.each do |resource|
      options.merge!(resource: resource)
      content = self.content_type.new(options)
      if @collection.is_a?(Array)
        @collection << content
      elsif @collection.is_a?(Hash)
        @collection[content.name] = content
      end
    end
  end

  def collection_type
    Array
  end

  def content_type
    raise 'Must implement content_type in child class of BitVault::Collection'
  end
end
