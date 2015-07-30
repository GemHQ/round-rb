module Round
  module Pageable
    PAGE_LIMIT = 100

    class PageError < StandardError
      def initialize(**options)
        @message = options[:message]
        @message ||= "No page at index: #{options[:index]}"
        super(@message)
      end
    end

    module Initializer
      def initialize(options = {}, &block)
        @_page = options.delete(:page) || 0
        @_constructor = options[:resource] if options[:resource].is_a?(Proc)
        options[:resource] = @_constructor.call(
          limit: PAGE_LIMIT.to_s,
          offset: (@_page * PAGE_LIMIT).to_s
        ) if @_constructor

        super(options, &block)
      end
    end

    def self.included(klass)
      klass.send(:prepend, Initializer)
      def klass.is_pageable?
        true
      end
    end

    attr_reader :_page

    def page(index=nil)
      return @_page if index.nil?
      raise(PageError, message: "Collection not pageable") unless @_constructor
      raise(PageError, index: index) unless @_page >= 0
      p = self.class.new(resource: @_constructor, client: @client, page: index)
      # TODO: It would be ideal if we could know if there are more pages without
      # making the above request first. Possibly a has-more property in the API
      # response.
      raise(PageError, index: index) unless p.size >= 1
      p
    end

    def next_page
      page(@_page + 1)
    end

    def previous_page
      page(@_page - 1)
    end

  end
end
