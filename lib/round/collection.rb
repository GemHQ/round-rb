class Round::Collection < Round::Base
  include Enumerable

  def_delegators :@collection, :[]

  attr_accessor :collection

  def each(&block)
    @collection.each(&block)
  end

  def initialize(options = {})
    super(options)
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
    @collection << content
  end

  def content_type
    Round::Base
  end

  def content_key
    :name
  end
  
end
