require_relative "setup"
require_relative "blockchaintest"

include BitVault::Encodings

require "bitvault/blockchain/biteasy"

describe "BitEasy.io interface" do


# This test is currently timing out
=begin
  it "unspent" do

    result = BlockchainTest.biteasy.unspent BlockchainTest.address_list
puts "unspent finished"

    assert_kind_of Array, result

    result.each do |output|
      assert_kind_of BitVault::Bitcoin::Output, output
    end

    output = result[0]

    assert_equal(
      # TODO:
      # transaction hashes should be hex, not base58.
      # https://github.com/BitVault/bitvault-rb/issues/1
      "BcxLvpD8cYB7qQwy9Hg8KcjM1nfD4M4XrFSkn8TTk7RY",
      base58(output.transaction_hash)
    )

    assert_equal 0, output.index
    assert_equal 1000000000, output.value
  end
=end


  # Test BitEasy#transactions
  it "transaction" do

    transaction =
      BlockchainTest.biteasy.transaction BlockchainTest.transaction_list[0]

    puts JSON.pretty_generate transaction

=begin
    # Testing
    require "bitvault/blockchain/blockr"

    blockr = BlockchainTest.blockr
    tx_blockr = (blockr.transactions BlockchainTest.transaction_list[0])[0]
    puts
    puts "**************"
    puts JSON.pretty_generate tx_blockr
    puts "**************"
=end
  end

end
