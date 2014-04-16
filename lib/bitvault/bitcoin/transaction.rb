
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
        transaction.add_output Output.new(data)
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
      base58(self.binary_hash)
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

      @native.signature_hash_for_input(
        prev_out.index, nil, script.to_blob
      )
    end

    def sign(signer)
    end

  end

end
