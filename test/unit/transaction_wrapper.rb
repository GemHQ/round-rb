require_relative "setup"

include BitVault::Bitcoin

describe "Transaction" do
  include BitVaultTests::Bitcoin

  describe "created with no arguments" do

    def transaction
      @transaction ||= Transaction.new()
    end

    it "has a native Tx" do
      assert_kind_of Bitcoin::Protocol::Tx, transaction.native
    end

    it "has no inputs" do
      assert_empty transaction.inputs
    end

    it "has no outputs" do
      assert_empty transaction.outputs
    end

    it "has binary and base58 hash values" do
      refute_empty transaction.binary_hash
      assert_kind_of String, transaction.binary_hash
      refute_empty transaction.base58_hash
      assert_kind_of String, transaction.base58_hash
    end

    it "fails validation" do
      report = transaction.validate_syntax
      assert_equal false, report[:valid]
      assert_equal :lists, report[:error].first
    end

  end

  describe "created from a full Hash representation" do
  end

  describe "created from a valid Bitcoin::Protocol::Tx" do

    def transaction
      @transaction ||= Transaction.native(disbursal_tx)
    end

    it "has binary and base58 hash values" do
      assert_equal disbursal_tx.binary_hash, transaction.binary_hash
      refute_empty transaction.base58_hash
      assert_kind_of String, transaction.base58_hash
    end

    describe "inputs" do
      it "has sparse inputs" do
        transaction.inputs.each do |input|
          assert_kind_of SparseInput, input
        end
      end

      it "has the correct number" do
        assert_equal disbursal_tx.inputs.size, transaction.inputs.size
      end
    end

    describe "outputs" do
      it "has the correct number" do
        assert_equal disbursal_tx.outputs.size, transaction.outputs.size
      end

      it "has Output instances" do
        transaction.outputs.each_with_index do |output, i|
          assert_kind_of Output, output
        end
      end
    end

    it "passes validation" do
      report = transaction.validate_syntax
      assert_equal true, report[:valid]
    end

    it "can be encoded as JSON" do
      # TODO: check attributes after round trip
      JSON.parse(transaction.to_json)
    end

  end

  describe "Modifications" do

    def previous_transaction
      @previous ||= Transaction.native(disbursal_tx)
    end

    describe "when adding inputs" do

      def input
        @input ||= Input.new :output => previous_transaction.outputs[0]
      end

      def modified
        transaction = Transaction.new
        @starting_hash = transaction.base58_hash
        transaction.add_input input
        transaction
      end

      it "has the added input" do
        transaction = modified
        assert_equal 1, transaction.inputs.size
        assert_equal 1, transaction.native.inputs.size
        assert_equal input, transaction.inputs.first
      end

      it "modifies the hash" do
        transaction = modified
        transaction.add_input input
        refute_equal @starting_hash, transaction.base58_hash
      end

      it "computes a sig_hash for the input" do
        sig_hash = modified.inputs[0].sig_hash
        assert_kind_of String, sig_hash
        refute_empty sig_hash
      end

    end

    describe "when adding outputs" do

      def script_string
        "OP_DUP OP_HASH160 7b936f13a9a2f0f2c30520c5cb24bc76a148d696 OP_EQUALVERIFY OP_CHECKSIG"
      end

      def output
        @output ||= Output.new(:value => 21_000, :script => script_string)
      end

      def modified
        transaction = Transaction.new
        @starting_hash = transaction.base58_hash
        transaction.add_output output
        transaction
      end

      it "has the added output" do
        transaction = modified
        assert_equal 1, transaction.outputs.size
        assert_equal 1, transaction.native.outputs.size
        assert_equal output, transaction.outputs.last
      end

      it "provides the output with itself and an index" do
        transaction = modified
        output = transaction.outputs.last
        assert_equal transaction, output.transaction
        assert_equal transaction.outputs.size - 1, output.index
      end

      it "modifies the hash" do
        transaction = modified
        refute_equal @starting_hash, transaction.base58_hash
      end


    end

  end


end


