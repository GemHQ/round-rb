
module BitVault::Bitcoin

  class Script
    include BitVault::Encodings

    attr_reader :native

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
          @blob = Bitcoin::Script.to_pubkey_script(public_key)
        elsif (keys = options[:public_keys]) && (needed = options[:needed])
          @blob = Bitcoin::Script.to_multisig_script(needed, *keys)
        else
          raise ArgumentError
        end
      end

      @hex = hex(@blob)
      @native = Bitcoin::Script.new @blob
      @string = @native.to_string
    end

    def to_s
      @string
    end

    def to_hex
      @hex
    end

    def to_blob
      @blob
    end

    alias_method :to_binary, :to_blob

    def type
      case self.native.type
      when :hash160
        :pubkey_hash
      when :p2sh
        :script_hash
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
