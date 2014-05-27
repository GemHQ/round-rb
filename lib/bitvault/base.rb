class BitVault::Base
  attr_reader :resource

  def initialize(options = {})
    raise ArgumentError unless options[:resource]
    @resource = options[:resource]
  end
end