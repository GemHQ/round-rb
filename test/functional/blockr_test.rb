require_relative "setup"

require "bitvault/blockchain/blockr"

include BitVault::Encodings
include BitVaultTests

describe "Blockr.io interface" do

  def blockr
    BitVault::Blockchain::Blockr.new :test
  end

  it "can query unspent outputs" do

    result = blockr.unspent TestnetAssets.address_list

    assert_kind_of Array, result

    result.each do |output|
      assert_kind_of BitVault::Bitcoin::Output, output

      # Check that unspent outputs report their confirmations,
      # should be a large positive number
      assert output.confirmations > 10_000
    end

    output = result[0]

    assert_equal(
      # TODO:
      # transaction hashes should be hex, not base58.
      "BcxLvpD8cYB7qQwy9Hg8KcjM1nfD4M4XrFSkn8TTk7RY",
      base58(output.transaction_hash)
    )

    assert_equal 0, output.index
    assert_equal 1000000000, output.value
  end



  # Test Blocker#balance
  it "can query balance by address list" do

    balances = blockr.balance TestnetAssets.address_list

    balances.each do |address, balance|
      assert_equal balance, TestnetAssets.expected_balances[address]
    end
  end


  # Test Blocker#balance
  it "can query with a one-element address list" do

    TestnetAssets.address_list.each do |address|
      balance = blockr.balance [ address ]
      assert_equal balance[address], TestnetAssets.expected_balances[address]
    end
  end


  # Test Blocker#balance
  it "can query balance by single address" do

    TestnetAssets.address_list.each do |address|
      balance = blockr.balance address
      assert_equal balance[address], TestnetAssets.expected_balances[address]
    end
  end


  # Test Blocker#transactions
  it "can query transaction info" do

    transactions =
      blockr.transactions TestnetAssets.transaction_list

    transactions.each do |tx|
      assert tx.is_a? BitVault::Bitcoin::Transaction

      # TODO: check that the tx id is the same as what we put in
    end

  end


  # Test Blockr#block_info
  it "can retrieve blocks" do

    block_info = TestnetAssets.block_info

    block_info.each do |block, stored_info|

      stored = stored_info["data"]

      retrieved_info = blockr.block_info block
      retrieved = retrieved_info[0]

      stored.each do |key, value|
        assert_equal value, retrieved[key.to_sym]
      end

    end

  end


  # TODO: add tests for block_txs

end
