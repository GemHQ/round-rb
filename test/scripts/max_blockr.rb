# Determines the maximum number of addresses Blockr will honor an 'unspent'
# request for, retrieving addresses from the blockchain as necessary.


require "set"

require_relative "setup"
require "bitvault/blockchain/blockr"


blockr = BitVault::Blockchain::Blockr.new :test


# Accumulate addresses
block = :last
addresses = Set.new
request_size = 20
max_requests = nil
loop do
  puts "Block: #{block}"

  # Obtain addresses
  block_data = (blockr.block_txs block)[0]
  txs = block_data[:txs]
  txs.each do |tx|
    trade = tx[:trade]
    outputs = trade[:vouts]
    outputs.each do |output|
      addresses << output[:address]
    end
    inputs = trade[:vins]
    inputs.each do |input|
      addresses << input[:address]
    end
  end

  # Try to retrieve unspent data
  while request_size <= addresses.size and not max_requests
    blockr.max_per_request = request_size
    puts "Retrieving unspent for #{request_size} addresses"
    begin
      unspent = blockr.unspent addresses.to_a[0...request_size]
    rescue RuntimeError => e
      puts e.message.class
      if e.message =~ /Too many addresses/
        max_requests = request_size - 1
      else
        puts "Terminating due to unknown error:"
        puts e.class
        max_requests = -1
      end
    end

    request_size += 1
  end

  # Determine next block
  block = block_data[:nb] - 1

  break if max_requests
end

puts "Obtained #{addresses.size} addresses"
addresses.each do |address|
  puts address
end

puts "Max number of addresses for Blockr unspent call: #{max_requests}"
