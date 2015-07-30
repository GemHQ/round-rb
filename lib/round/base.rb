module Round
  class Base
    attr_reader :resource

    def initialize(resource:, client:, **options)
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

    def self.is_pageable?
      false
    end

    def self.association(name, klass)
      define_method(name) do |page: 0, fetch: true|
        if Kernel.const_get(klass).is_pageable?
          res = Proc.new { |options = {}| @resource.send(name, **options) }
        end
        res ||= @resource.send(name)

        obj = Kernel.const_get(klass).new(
          resource: res, client: @client, page: page, populate: fetch)
        fetch ? obj.refresh : obj
      end
    end

  end
end
