module Round
  class Base
    attr_reader :resource

    def initialize(resource:, client:, **kwargs)
      @resource = resource
      @client = client
    end

    def refresh
      @resource = @resource.get
      self
    end

    def method_missing(meth, *args, &block)
      @resource.send(meth, *args, &block)
    rescue => e
      @resource.attributes.fetch(meth) do
        raise e
      end
    end

    def hash_identifier
      send :[], self.class.hash_identifier
    end

    def self.hash_identifier
      "key"
    end

    def self.association(name, klass)
      define_method(name) do
        Kernel.const_get(klass).new(resource: @resource.send(name), client: @client).refresh
      end
    end

  end
end
