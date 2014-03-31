require_relative "setup"

include BitVault::Bitcoin

describe "Transaction" do
  include BitVaultTests::Fixtures

  describe "created with no arguments" do

    def transaction
      @transaction ||= Transaction.new()
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
  end

  describe "created from a Bitcoin::Protocol::Tx" do

    def transaction
      # disbursal_tx is defined in the fixtures
      @transaction ||= Transaction.new(disbursal_tx)
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

  end

end


