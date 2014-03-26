require "bitcoin"

module BitVault::Bitcoin

  module Encodings
    extend self

    def hex(blob)
      blob.unpack("H*")[0]
    end

    def decode_hex(string)
      [string].pack("H*")
    end

    def base58(blob)
      Bitcoin.encode_base58(self.hex(blob))
    end

    def decode_base58(string)
      self.decode_hex(Bitcoin.decode_base58(string))
    end
  end

  # a validator that checks syntax only, not previous outputs
  class TransactionValidator < Bitcoin::Validation::Tx

    def initialize(tx)
      @tx, @errors = tx, []
    end

    def validate(opts = {})
      super :rules => [:syntax]
    end
    
  end


  class Transaction

    attr_reader :native
    def initialize(&block)
      @native = Builder.build_tx(&block)
      @inputs = []
      @outputs = []
      @native.outputs.size.times do |i|
        @outputs << Output.new(@native, i)
      end
    end

    def modify(&block)
      yield @native
      @native = Bitcoin::Protocol::Tx.new @native.to_payload
    end

    def validate
      validator = TransactionValidator.new(@native)
      valid = validator.validate :rules => [:syntax]
      {:valid => valid, :error => validator.error}
    end

    def add_input(input)
      @inputs << input
      self.modify do |native|
        native.add_in input.native
      end
      input.sig_hash = self.sig_hash(input)
    end

    def to_json(*a)
      {
        :version => @native.ver,
        :lock_time => @native.lock_time,
        :hash => base58(@native.binary_hash),
        :inputs => @inputs,
        :outputs => @outputs,
      }.to_json(*a)
    end

    def sig_hash(input)
      # NOTE: we only allow SIGHASH_ALL at this time
      # https://en.bitcoin.it/wiki/OP_CHECKSIG#Hashtype_SIGHASH_ALL_.28default.29
      prev_out = input.output
      @native.signature_hash_for_input(
        prev_out.index, nil, prev_out.script.blob
      )
    end

  end

  class Output
    attr_reader :native, :transaction, :index, :value, :script
    def initialize(transaction, index)
      # FIXME. probably should be taking the wrapper Transaction instance
      @transaction = transaction
      @index = index
      @native = transaction.outputs[index]
      @value = @native.value
      @script = BitVault::Bitcoin::Script.blob @native.pk_script
      #pp @native
    end

    def to_json(*a)
      {
        :transaction_hash => base58(@transaction.binary_hash),
        :index => @index,
        :value => @value,
        :script => @script,
      }.to_json(*a)
    end

  end


  class Input

    attr_reader :native, :output
    def initialize(output)
      @native = Bitcoin::Protocol::TxIn.new
      @output = output

      @native.prev_out = @output.transaction.binary_hash
      @native.prev_out_index = @output.index
    end

    def sig_hash=(string)
      @sig_hash = string
    end

    def script_sig=(string)
      script = BitVault::Bitcoin::Script.string(string)
      @script_sig = string
      @native.script_sig = script.blob
    end

    def to_json(*a)
      {
        :output => @output,
        :sig_hash => base58(@sig_hash || ""),
        :script_sig => @script_sig || ""
      }.to_json(*a)
    end

  end


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

    def to_json(*a)
      {
        :type => self.native.type,
        :string => self.to_s
      }.to_json(*a)
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


