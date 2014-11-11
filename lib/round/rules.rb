module Round

  class Wrapper
    extend Forwardable

    def_delegators :resource, :url

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end
  end

  class DictWrapper
    include Enumerable
    extend Forwardable
    def_delegators :resource, :url

    attr_reader :resource
    def initialize(resource)
      @resource = resource
      self.refresh
    end

    def wrap
      raise NotImplementedError
    end

    def each(&block)
      @cache.definitions.each(&block)
    end

    def refresh
      @cache = @resource.get
      @definitions = {}
      @cache.definitions.each do |key, value|
        @definitions[key] = self.wrap(value)
      end
      self
    end

    def [](key)
      @definitions[key]
    end

    def keys
      @definitions.keys
    end

    def to_hash
      @cache.definitions
    end

  end

  class Rules < DictWrapper

    def wrap(data)
      Rule.new(data)
    end

    def add(name)
      self.wrap @resource.add(:name => name)
    end

  end

  class Rule < Wrapper

    def_delegators :resource, :name, :data

    def set(content)
      content.each do |name, spec|
        case spec[:type]
        when "wallet", "account"
          resource = spec[:value]
          spec[:value] = {:url => resource[:url]}
        end
      end
      @resource.set(content)
    end

    def delete
      @resource.delete.response.data
    end

  end

end
