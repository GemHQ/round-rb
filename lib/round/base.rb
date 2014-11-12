class Round::Base
  extend Forwardable
  attr_reader :resource

  def_delegators :@resource, :url, :[]

  def initialize(options = {})
    raise ArgumentError, 'A resource must be set on this object' unless options[:resource]
    @resource = options[:resource]
  end


end
