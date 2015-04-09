module Round
  class Base
    attr_reader :resource

    def initialize(options = {})
      raise ArgumentError, 'A resource must be set on this object' unless options[:resource]
      @resource = options[:resource]
      @client = options[:client]
    end

    def refresh
      @resource = @resource.get
      self
    end

    def method_missing(meth, *args, &block)
      @resource.send(meth, *args, &block)
    rescue
      @resource.attributes[meth]
    end

    def hash_identifier
      send :[], self.class.hash_identifier
    end

    def self.hash_identifier
      "key"
    end

    def self.association(name, klass)
      define_method(name) do
        Kernel.const_get(klass).new(resource: @resource.send(name), client: @client)
      end
    end

  end
end
