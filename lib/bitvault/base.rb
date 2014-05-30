class BitVault::Base
  attr_reader :resource

  def initialize(options = {})
    raise ArgumentError, 'A resource must be set on this object' unless options[:resource]
    @resource = options[:resource]
  end
end