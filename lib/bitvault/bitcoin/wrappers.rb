require "bitcoin"

module BitVault::Bitcoin

  module Encodings
    extend self

    def hex(blob)
      blob.unpack("H*")[0]
    end
  end

  #class Hash160
    #def self.blob(blob)
      #self.new Encodings.hex(blob)
    #end

    #def self.hex(hex)
      #self.new(hex)
    #end

    #attr_reader :hex
    #def initialize(hex)
      #@hex = hex
    #end

    #def to_s
      #Bitcoin.hash160(@hex)
    #end

    #def to_address
      #Bitcoin.hash160_to_address(self.to_s)
    #end

    #def to_p2sh_address
      #Bitcoin.hash160_to_p2sh_address(self.to_s)
    #end

  #end

  class Script

    def self.blob(blob)
      self.new(blob)
    end

    def self.string(string)
      blob = Bitcoin::Script.binary_from_string(string)
      self.new(blob)
    end

    attr_reader :hex, :blob
    def initialize(blob)
      @blob = blob
      @hex = Encodings.hex(blob)
    end

    def native
      Bitcoin::Script.new @blob
    end

    def to_s
      self.native.to_string
    end

    def hash160
      #Hash160.hex(@hex)
      Bitcoin.hash160(@hex)
    end

    def p2sh_script
      self.class.new Bitcoin::Script.to_p2sh_script(self.hash160)
    end

    def p2sh_address
      Bitcoin.hash160_to_p2sh_address(self.hash160)
    end

  end

  class Address
    #def hash160
      #Bitcoin.hash160_from_address(@data)
    #end
  end

end


