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
      self.native(native)
    end

    def self.build(&block)
      transaction = self.new
      yield transaction
      transaction
    end

    def self.native(tx)
      transaction = self.new()
      transaction.instance_eval do
        @native = tx
        tx.inputs.each_with_index do |input, i|
          @inputs << SparseInput.new(input.prev_out, input.prev_out_index)
        end
        tx.outputs.each_with_index do |output, i|
          @outputs << Output.new(
            :transaction => transaction,
            :index => i,
            :value => output.value,
            :script => {:blob => output.pk_script}
          )
        end
      end

      transaction
    end

    def self.data(hash)
      version, lock_time, hash, inputs, outputs = 
        hash.values_at :version, :lock_time, :hash, :inputs, :outputs
      transaction = self.new

      outputs.each do |data|
        transaction.add_output Output.new(
          :value => data[:value],
          :script => data[:script]
        )
      end

      # TODO: figure out a way to trigger sig_hash computation
      # at the right time so we don't have to add inputs after outputs.
      inputs.each do |data|
        output = Output.new(data[:output])
        input = Input.new(output)
        transaction.add_input input
        # FIXME: verify that the supplied and computed sig_hashes match
        #puts :sig_hashes_match => (data[:sig_hash] == input.sig_hash)
      end

      # TODO: validate transaction syntax
      transaction
    end

    attr_reader :native, :inputs, :outputs

    def initialize
      @native = native || Bitcoin::Protocol::Tx.new
      @inputs = []
      @outputs = []
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

    def add_input(arg)
      # TODO: allow specifying prev_tx and index with a Hash.
      # Possibly stop using SparseInput.
      if arg.is_a? Output
        input = Input.new(arg)
      else
        input = arg
      end

      @inputs << input
      self.update_native do |native|
        native.add_in input.native
      end
      #input.sig_hash = self.sig_hash(input)
      input.binary_sig_hash = self.sig_hash(input)
    end

    def add_output(output)
      unless output.is_a? Output
        output = Output.new(output)
      end

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

    attr_reader :native, :output, :binary_sig_hash,
      :signatures, :sig_hash, :script_sig

    def initialize(output)
      @native = Bitcoin::Protocol::TxIn.new
      @output = output

      @native.prev_out = @output.transaction_hash
      @native.prev_out_index = @output.index
      @signatures = []
    end

    def binary_sig_hash=(blob)
      @binary_sig_hash = blob
      @sig_hash = Encodings.base58(blob)
    end

    def script_sig=(string)
      script = Script.new(string)
      @script_sig = string
      @native.script_sig = script.blob
    end

    def to_json(*a)
      {
        :output => self.output,
        :signatures => self.signatures.map {|b| Encodings.base58(b) },
        :sig_hash => self.sig_hash || "",
        :script_sig => self.script_sig || ""
      }.to_json(*a)
    end

  end


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


