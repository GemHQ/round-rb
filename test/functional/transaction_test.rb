require_relative "setup"
require_relative "blockchaintest"

include BitVault::Encodings

require "bitvault/blockchain/blockr"
require "bitvault/bitcoin/transaction"

describe "Transaction class" do


  # Test suggested_fee
  it "can query total outputs" do

    Bitcoin.network = :testnet3

    blockr = BlockchainTest.blockr

    # FIXME: make this a more realistic test with a non-zero expected
    # value.

    tx = BitVault::Bitcoin::Transaction.new
    unspent_outputs = blockr.unspent BlockchainTest.address_list
    unspent_outputs.each do |output|
      tx.add_input output
    end

    assert_equal tx.suggested_fee, 0
  end


  # Test total outputs
  it "can query total outputs" do

    Bitcoin.network = :testnet3

    blockr = BlockchainTest.blockr

    tx = BitVault::Bitcoin::Transaction.new
    unspent_outputs = blockr.unspent BlockchainTest.address_list
    unspent_outputs.each do |output|
      tx.add_output output
    end

    assert_equal tx.output_value, 61_000_000_00
  end

end
