
module BitVault::Bitcoin

  class SparseInput
    include BitVault::Encodings

    def initialize(binary_hash, index)
      @output = {
        :transaction_hash => base58(binary_hash),
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
    include BitVault::Encodings

    attr_reader :native, :output, :binary_sig_hash,
      :signatures, :sig_hash, :script_sig

    def initialize(output, options={})
      @native = Bitcoin::Protocol::TxIn.new
      @output = output

      @native.prev_out = @output.transaction_hash
      @native.prev_out_index = @output.index

      @signatures = []
    end

    def binary_sig_hash=(blob)
      @binary_sig_hash = blob
      @sig_hash = base58(blob)
    end

    def script_sig=(blob)
      script = Script.new(:blob => blob)
      @script_sig = script.to_s
      @native.script_sig = blob
    end


    def to_json(*a)
      {
        :output => self.output,
        :signatures => self.signatures.map {|b| base58(b) },
        :sig_hash => self.sig_hash || "",
        :script_sig => self.script_sig || ""
      }.to_json(*a)
    end

  end


end


