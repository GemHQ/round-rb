require_relative "setup"

require "bitvault/bitcoin"
include BitVault::Bitcoin



# client side

bitvault = MoneyTree::Master.new :network => :bitcoin_testnet

live = MoneyTree::Master.new :network => :bitcoin_testnet
backup = MoneyTree::Master.new :network => :bitcoin_testnet

public_addresses = {
  :live => live.to_serialized_address,
  :backup => backup.to_serialized_address
}


# server side
wallet = Wallet.new(
  :private => bitvault.to_serialized_address(:private),
  :public => public_addresses
)


# grab a node and start to play
path = "m/1/4/7"
trinode = wallet.trinode(path)
p2sh_address = trinode.script.p2sh_address

puts "p2sh address: #{p2sh_address}"



test_chain = TestMockchain.new
t1 = test_chain.disburse(p2sh_address)


# set up third party address to receive payment
key = Bitcoin::Key.new
address = key.addr

def add_input(tx, redeem_script, options)
  txin = Bitcoin::Protocol::TxIn.new
  prev_tx = options[:prev]
  index = options[:index]

  txin.prev_out = prev_tx.binary_hash
  txin.prev_out_index = index
  tx.add_in txin

  txin.sig_hash = tx.signature_hash_for_input(0, nil, redeem_script.blob)

  txin
end

# server side
t2 = Builder.build_tx do |t|
  t.output do |o|
    o.value (test_chain.mining_fee / 8)
    o.script do |s|
      s.recipient address
    end
  end
end

txin = add_input(t2, trinode.script, :prev => t1, :index => 0)

# pretend we send some representation of the transaction to the client

# client side
# derive the node (how is the path communicated?)
node = live.node_for_path(path)
live_key = Bitcoin::Key.new(node.private_key.to_hex, node.public_key.to_hex)
live_sig = live_key.sign(txin.sig_hash) + "\x01"

# pretend the client sends back the signature

# server side
bv_key = trinode.keys[:bitvault]
bv_sig = bv_key.sign(txin.sig_hash) + "\x01"

# server side
def p2sh_script_sig(redeem_script, *signatures)
  multisig = Bitcoin::Script.to_multisig_script_sig(*signatures)
  string = Script.blob(multisig).to_s
  Bitcoin::Script.binary_from_string("#{string} #{redeem_script.hex}")
end

txin.script_sig = p2sh_script_sig(trinode.script, bv_sig, live_sig)


# Now verify that the input is valid
script_pubkey = t1.outputs[0].pk_script
full_script = txin.script_sig + script_pubkey
script = Bitcoin::Script.new(full_script)

puts "valid p2sh input? #{t2.verify_input_signature(0, t1)}"






