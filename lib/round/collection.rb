module Round
  class Collection < Round::Base
    include Enumerable
    attr_reader :collection

    def initialize(options = {}, &block)
      super(options)
      options.delete(:resource)
      self.populate_data(options, &block)
    end

    def populate_data(options = {}, &block)
      @collection ||= []
      @hash ||= {}
      @resource.list.each do |resource|
        content = self.content_type.new(options.merge(resource: resource, client: @client))
        yield content if block
        self.add(content)
      end if @resource.list
    end

    def refresh(options = {})
      @collection = []
      populate_data(options)
    end

    def add(content)
      @collection << content
      if content.name
        @hash[content.name] = content
      else
        @hash[content.key] = content
      end
    end

    def content_type
      Round::Base
    end
    
    def [](key)
      if key.is_a?(Fixnum)
        @collection[key]
      else
        @hash[key]
      end
    end

    def method_missing(meth, *args, &block)
      @collection.send(meth, *args, &block)
    rescue
      super
    end

  end
end