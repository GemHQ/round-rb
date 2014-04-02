
module BitVault::Bitcoin

  class Script

    attr_reader :hex, :blob, :native

    def initialize(options)
      # literals
      if options.is_a? String
        @blob = Bitcoin::Script.binary_from_string options
      elsif string = options[:string]
        @blob = Bitcoin::Script.binary_from_string string
      elsif options[:blob]
        @blob = options[:blob]
      # arguments for constructing
      else
        if address = options[:address]
          @blob = Bitcoin::Script.to_address_script(address)
        elsif public_key = options[:public_key]
          @blob = Bitcoin::Script.to_pubkey_script(address)
        elsif public_keys = options[:public_keys]
          @blob = Bitcoin::Script.to_multisig_script(address)
        else
          raise ArgumentError
        end
      end

      @hex = Encodings.hex(blob)
      @native = Bitcoin::Script.new @blob
      @string = @native.to_string
    end

    def to_s
      @string
    end

    def type
      if self.native.type == :hash160
        :address
      else
        self.native.type
      end
    end

    def to_hash
      {
        :type => self.type,
        :string => self.to_s
      }
    end

    def to_json(*a)
      self.to_hash.to_json(*a)
    end

    def hash160
      Bitcoin.hash160(@hex)
    end

    def p2sh_script
      self.class.new Bitcoin::Script.to_p2sh_script(self.hash160)
    end

    def p2sh_address
      Bitcoin.hash160_to_p2sh_address(self.hash160)
    end

  end

end
