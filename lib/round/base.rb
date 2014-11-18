class Round::Base
  attr_reader :resource

  def initialize(options = {})
    raise ArgumentError, 'A resource must be set on this object' unless options[:resource]
    @resource = options[:resource]
    @client = options[:client]
  end

  def method_missing(meth, *args, &block)
    @resource.send(meth, *args, &block)
  end

end
