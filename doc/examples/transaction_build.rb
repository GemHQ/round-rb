require "bitvault/bitcoin"

include BitVault::Bitcoin

vendor_key = ::Bitcoin::Key.new
vendor_key.generate
vendor_address = vendor_key.addr

change_key = ::Bitcoin::Key.new
change_key.generate
change_address = change_key.addr


transaction = Transaction.build do |t|
  t.add_input(
    :transaction_hash => "7KxGcWup3dvGbms5asKi3M6s2HL998oroR9qWq4BgFsY",
    :index => 0,
    :script => "OP_DUP OP_HASH160 9a80c2e7792a380423f2f5a918fd139b07556fea OP_EQUALVERIFY OP_CHECKSIG"
  )

  t.add_output(
    :value => 25_000,
    :script => {
      :address => vendor_address
    }
  )

  t.add_output(
    :value => 5_000,
    :script => {
      :address => change_address
    }
  )
end

puts JSON.pretty_generate(transaction)

puts report = transaction.validate_syntax

