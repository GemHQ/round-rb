require_relative "setup"
require_relative "blockchaintest"

include BitVault::Encodings

require "bitvault/blockchain/biteasy"

describe "BitEasy.io interface" do


# Need to solve the timeout problems to actually finish and pass
# this test.
=begin
  it "unspent" do

    result = BlockchainTest.biteasy.unspent BlockchainTest.address_list
    #result = BlockchainTest.biteasy.unspent BlockchainTest.address_list[0]
puts "unspent finished"

    assert_kind_of Array, result

    result.each do |output|
      assert_kind_of BitVault::Bitcoin::Output, output
    end

    output = result[0]
=end

=begin
    assert_equal(
      # TODO:
      # transaction hashes should be hex, not base58.
      # https://github.com/BitVault/bitvault-rb/issues/1
      "BcxLvpD8cYB7qQwy9Hg8KcjM1nfD4M4XrFSkn8TTk7RY",
      base58(output.transaction_hash)
    )
=end

    #assert_equal 0, output.index
    #assert_equal 1000000000, output.value
  #end


  # Test BitEasy#transactions
  it "transaction" do

    transactions =
      BlockchainTest.biteasy.transaction BlockchainTest.transaction_list

    puts JSON.pretty_generate transactions
  end

end
