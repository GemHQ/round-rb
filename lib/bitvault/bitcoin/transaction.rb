
module BitVault::Bitcoin

  class Transaction
    include BitVault::Encodings

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
      # TODO: reconsider use of instance_eval
      transaction.instance_eval do
        @native = tx
        tx.inputs.each_with_index do |input, i|
          # We use SparseInput because it does not require the retrieval
          # of the previous output.  Its functionality should probably be
          # folded into the Input class.
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

      report = transaction.validate_syntax
      unless report[:valid] == true
        raise "Invalid syntax:  #{report[:errors].to_json}"
      end
      transaction
    end

    def self.raw(raw_tx)
      self.native ::Bitcoin::Protocol::Tx.new(raw_tx)
    end

    def self.hex(hex)
      self.raw decode_hex hex
    end

    def self.data(hash)
      version, lock_time, hash, inputs, outputs = 
        hash.values_at :version, :lock_time, :hash, :inputs, :outputs

      transaction = self.new

      outputs.each do |data|
        transaction.add_output Output.new(data)
      end

      #FIXME: we're not handling sig_scripts for already signed inputs.

      inputs.each_with_index do |data, index|
        transaction.add_input data[:output]

        ## FIXME: verify that the supplied and computed sig_hashes match
        #puts :sig_hashes_match => (data[:sig_hash] == input.sig_hash)
      end

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
      @inputs.each_with_index do |input, i|
        native = @native.inputs[i]
        # Using instance_eval here because I really don't want to expose
        # Input#native=.  As we consume more and more of the native
        # functionality, we can dispense with such ugliness.
        input.instance_eval do
          @native = native
        end
        if input.is_a? Input
          input.binary_sig_hash = self.sig_hash(input)
        end
        # TODO: is this re-nativization necessary for outputs, too?
      end
    end

    def validate_syntax
      update_native
      validator = Bitcoin::Validation::Tx.new(@native, nil)
      valid = validator.validate :rules => [:syntax]
      {:valid => valid, :error => validator.error}
    end

    def validate_script_sigs
      bad_inputs = []
      valid = true
      @inputs.each_with_index do |input, index|
        unless self.native.verify_input_signature(index, input.output.transaction.native)
          # TODO: confirm whether we need to mess with the block_timestamp arg
          valid = false
          bad_inputs << index
        end
      end
      {:valid => valid, :inputs => bad_inputs}
    end

    # Takes one of
    #
    # * an instance of Input
    # * an instance of Output
    # * a Hash describing an Output
    #
    def add_input(arg)
      # TODO: allow specifying prev_tx and index with a Hash.
      # Possibly stop using SparseInput.
      if arg.is_a? Input
        input = arg
      else
        input = Input.new(
          :transaction => self,
          :index => @inputs.size,
          :output => arg
        )
      end

      @inputs << input
      self.update_native do |native|
        native.add_in input.native
      end
      input
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
      base58(self.binary_hash)
    end

    def hex_hash
      hex(self.binary_hash)
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
        :hash => base58(self.binary_hash),
        :inputs => self.inputs,
        :outputs => self.outputs,
      }
    end

    def sig_hash(input, script=nil)
      # NOTE: we only allow SIGHASH_ALL at this time
      # https://en.bitcoin.it/wiki/OP_CHECKSIG#Hashtype_SIGHASH_ALL_.28default.29

      prev_out = input.output
      script ||= prev_out.script

      @native.signature_hash_for_input(prev_out.index, nil, script.to_blob)
    end

    def set_script_sigs(*input_args, &block)
      # No sense trying to authorize when the transaction isn't usable.
      report = validate_syntax
      unless report[:valid] == true
        raise "Invalid syntax:  #{report[:errors].to_json}"
      end

      # Array#zip here allows us to iterate over the inputs in lockstep with any
      # number of sets of signatures.
      self.inputs.zip(*input_args) do |input, *input_arg|
        input.script_sig = yield input, *input_arg
      end
    end


    def suggested_fee
      @native.minimum_block_fee
    end


    # Total value being spent
    def output_value
      total = 0
      @outputs.each do |output|
        total += output.value
      end

      total
    end


  end

end
