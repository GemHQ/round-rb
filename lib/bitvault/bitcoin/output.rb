
module BitVault::Bitcoin

  class Output

    attr_accessor :metadata
    attr_reader :native, :transaction, :index, :value, :script

    def initialize(options)

      if options[:transaction_hash]
        @transaction_hash = options[:transaction_hash]
      elsif options[:transaction]
        @transaction = options[:transaction]
      end

      @index, @value = options.values_at :index, :value
      @metadata = options[:metadata] || {}

      if options[:script]
        @script = Script.new(options[:script])
      else
        raise ArgumentError, "No script supplied"
      end

      @native = Bitcoin::Protocol::TxOut.from_hash(
        "value" => @value.to_s,
        "scriptPubKey" => @script.to_s
      )
    end

    def set_transaction(transaction, index)
      @transaction_hash = nil
      @transaction, @index = transaction, index
    end

    def transaction_hash
      if @transaction
        Encodings.base58(@transaction.binary_hash)
      elsif @transaction_hash
        @transaction_hash
      else
        ""
      end
    end


    def to_hash
      {
        :transaction_hash => self.transaction_hash,
        :index => self.index,
        :value => self.value,
        :script => self.script,
        :metadata => self.metadata
      }
    end

    def to_json(*a)
      self.to_hash.to_json(*a)
    end

  end

end
