class Round::Collection < Round::Base
  include Enumerable
  attr_reader :collection

  def initialize(options = {}, &block)
    super(options)
    options.delete(:resource)
    self.populate_data(options, &block)
  end

  def populate_data(options, &block)
    @collection ||= []
    resource.list.each do |resource|
      content = self.content_type.new(options.merge(resource: resource))
      yield content if block
      self.add(content)
    end
  end

  def add(content)
    @collection << content
  end

  def content_type
    Round::Base
  end
  
  def method_missing(meth, *args, &block)
    @collection.send(meth, *args, &block)
  rescue
    super
  end

end
