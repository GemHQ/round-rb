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

  class Transaction

    def self.build_outputs(&block)
      native = Builder.build_tx(&block)
      self.new(native)
    end

    attr_reader :native, :inputs, :outputs

    def initialize(native=nil)

      @native = native || Bitcoin::Protocol::Tx.new
      @inputs = []
      @outputs = []

      @native.inputs.each_with_index do |input, i|
        @inputs << SparseInput.new(input.prev_out, input.prev_out_index)
      end

      @native.outputs.each_with_index do |output, i|
        @outputs << Output.new(
          :transaction => self,
          :index => i,
          :value => output.value,
          :pk_script => output.pk_script
        )
      end
    end

    def update_native
      yield @native if block_given?
      @native = Bitcoin::Protocol::Tx.new(@native.to_payload)
    end

    def validate
      update_native
      validator = Bitcoin::Validation::Tx.new(@native, nil)
      valid = validator.validate :rules => [:syntax]
      {:valid => valid, :error => validator.error}
    end

    def add_input(input)
      @inputs << input
      self.update_native do |native|
        native.add_in input.native
      end
      input.sig_hash = self.sig_hash(input)
    end

    def add_output(output)
      index = @outputs.size
      output.set_transaction self, index
      @outputs << output
      self.update_native do |native|
        native.add_out(output.native)
      end
    end

    def binary_hash
      update_native
      @native.binary_hash
    end

    def base58_hash
      Encodings.base58(self.binary_hash)
    end

    def version
      @native.ver
    end

    def lock_time
      @native.lock_time
    end

    def to_json(*a)
      self.to_hash.to_json(*a)
    end

    def to_hash
      {
        :version => self.version,
        :lock_time => self.lock_time,
        :hash => Encodings.base58(self.binary_hash),
        :inputs => self.inputs,
        :outputs => self.outputs,
      }
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

    attr_reader :native, :value, :script, :transaction, :index

    def initialize(options)
      @transaction, @index, @value =
        options.values_at :transaction, :index, :value
      if options[:script]
        @script = Script.string(options[:script])
      elsif options[:pk_script]
        @script = Script.blob(options[:pk_script])
      else
        raise ArgumentError, "No script supplied"
      end

      @native = Bitcoin::Protocol::TxOut.from_hash(
        "value" => @value.to_s,
        "scriptPubKey" => @script.to_s
      )
    end

    def set_transaction(transaction, index)
      @transaction, @index = transaction, index
    end

    def transaction_hash
      if @transaction
        Encodings.base58(@transaction.binary_hash)
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
      }
    end

    def to_json(*a)
      self.to_hash.to_json(*a)
    end

  end

  class SparseInput

    def initialize(binary_hash, index)
      @output = {
        :transaction_hash => Encodings.base58(binary_hash),
        :index => index,
      }
    end

    def to_json(*a)
      {
        :output => @output,
      }.to_json(*a)
    end

  end

  class Input

    attr_reader :native, :output, :sig_hash, :script_sig
    def initialize(output)
      @native = Bitcoin::Protocol::TxIn.new
      @output = output

      @native.prev_out = @output.transaction_hash
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
        :output => self.output,
        :sig_hash => Encodings.base58(self.sig_hash || ""),
        :script_sig => self.script_sig || ""
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


