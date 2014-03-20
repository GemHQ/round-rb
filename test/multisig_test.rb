require_relative "setup"

require "bitvault/bitcoin"
include BitVault::Bitcoin



## client side

# Create a multisig-wallet from scratch with two trees.
client_wallet = MultiWallet.generate [:live, :backup]

# The address for the "backup" tree should be stored offline.
backup_address = client_wallet.private_address(:backup)

# spawn a new wallet without the "backup" tree.
client_wallet = client_wallet.drop(:backup)

# derive the public tree addresses to provide to the server
public_addresses = client_wallet.public_addresses

## Here we pretend that we sent the server the appropriate MoneyTree addresses

## server side

# Create a wallet from scratch with one tree.
server_wallet = MultiWallet.generate [:bitvault]

# Create public-trees from the public addresses sent by the client
server_wallet.import(public_addresses)

# Prepare for a transaction

path = "m/1/4/7" # just some numbers I like
server_node = server_wallet.path(path)


# Disburse some coin to this node, so we can start spending
test_chain = TestMockchain.new
transaction_1 = test_chain.disburse(server_node.p2sh_address)

## Client tells the server some address to receive payment

other_key = Bitcoin::Key.new
address = other_key.addr


# server side

value = transaction_1.outputs[0].value

transaction_2 = Builder.build_tx do |t|
  t.output do |o|
    o.value (value)
    o.script do |s|
      s.recipient address
    end
  end
end


# the wallet node creates an input, adds it to the transaction, and
# prepares the sig_hash.
txin = server_node.add_input transaction_2,
  :prev => transaction_1, :index => 0

## Pretend we send some sensible representation of the transaction to
## the client, obviously including the wallet path.

client_node = client_wallet.path(path)

# MultiWallet nodes can sign with a specified private key
client_sig = client_node.sign(:live, txin.sig_hash)

## pretend the client sends back the signature

# MultiWallet nodes can also sign with all their private keys
signatures = server_node.signatures(txin.sig_hash)
signatures << client_sig

# the server constructs a proper p2sh script_sig from all the
# supplied signatures.
txin.script_sig = server_node.p2sh_script_sig(*signatures)


# Now verify that the input is valid
puts "valid p2sh input? #{transaction_2.verify_input_signature(0, transaction_1)}"






