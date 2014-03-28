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

    def self.json(string)
      data = JSON.parse(string, :symbolize_names => true)
      version, lock_time, hash, inputs, outputs =
        data.values_at :ver, :lock_time, :hash, :inputs, :outputs

      native = Bitcoin::Protocol::Tx.new

      native.ver = version
      native.lock_time = lock_time
      native.hash = hash

      tx = self.new(native)
      outputs.each do |params|
        output = Output.new(
          :index => params[:index],
          :value => params[:value],
          :script => params[:script][:string],
        )
        tx.add_output(output)
      end

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
        @outputs << Output.native(native, i)
      end
    end

    def modify(&block)
      yield @native
      @native = Bitcoin::Protocol::Tx.new @native.to_payload
    end

    def validate
      validator = Bitcoin::Validation::Tx.new(@native, nil)
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

    def add_output(output)
      @outputs << output
      self.modify do |native|
        native.add_out(output.native)
      end
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

    def self.native(native_transaction, index)
      native_output = native_transaction.outputs[index]

      output = self.new(
        :index => index,
        :native => {
          :transaction => native_transaction,
          :output => native_output
        }
      )
    end

    attr_reader :native, :transaction, :index, :value, :script

    def initialize(options)
      @index = options[:index]
      if natives = options[:native]
        @native_transaction = natives[:transaction]
        @native = natives[:output]
        @value = @native.value
        @script = BitVault::Bitcoin::Script.blob @native.pk_script
      else
        @native = Bitcoin::Protocol::Tx.new
        @value = options[:value]
        @script = BitVault::Bitcoin::Script.string(options[:script])
      end
    end

    def transaction=(transaction)
      @transaction = transaction
      @native_transaction = @transaction.native
      # do the tx.add_out here, or in the Transaction method?
    end


    def transaction_hash
      if @native_transaction
        @native_transaction.binary_hash
      else
        raise "This output has not been assigned to a transaction"
      end
    end

    def to_json(*a)
      {
        :transaction_hash => base58(self.transaction_hash),
        :index => @index,
        :value => @value,
        :script => @script,
      }.to_json(*a)
    end

  end

  class SparseInput

    def initialize(transaction_hash, index)
      @output = {
        :transaction_hash => base58(transaction_hash),
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

    attr_reader :native, :output
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


