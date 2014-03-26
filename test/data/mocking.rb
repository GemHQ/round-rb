$:.unshift "lib"

require_relative "../setup"
require "bitvault"
require "rbnacl"
require "openssl"

include BitVault::Bitcoin
include BitVault::Bitcoin::Encodings



data = Hash.new {|h,k| h[k] = {}}
client = data[:client]
server = data[:server]
network = data[:network]

# First generate all data for the client side

client_wallet = MultiWallet.generate [:hot, :cold]

client[:hot_seed] = hot_seed = client_wallet.trees[:hot].to_serialized_address(:private)
client[:cold_seed] = client_wallet.trees[:hot].to_serialized_address(:private)
client[:public_addresses] = client_wallet.public_addresses

# The server should NOT know the seed for constructing the
# "live" private-key tree, so we will encrypt it.  The server
# will only receive the values needed for a client to recover
# the live private key plaintext by means of a passphrase.

client[:encrypted_hot_seed] = {}


# We'll use NaCL's crypto_secretbox, which meens we need a 32 byte key.
# https://github.com/cryptosphere/rbnacl/wiki/Secret-Key-Encryption
# Random would be best, but if we wish to support passphrases, we'll need
# a good secure key derivation function, namely PBKDF2.  This requires a
# random salt, which must be stored somewhere.  For this example, we'll
# proceed on the assumption that all information required to recover
# the hot seed (except the passphrase) will be stored by our service.
client[:encrypted_hot_seed][:passphrase] = passphrase = "wrong pony generator brad"
salt = RbNaCl::Random.random_bytes(16)
client[:encrypted_hot_seed][:passphrase_salt] = base58(salt)

key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
  passphrase, salt,
  10_000, # number of iterations
  32      # key length in bytes
)

# The secret box algorithm requires a random nonce. We have to store this
# as well.
nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
client[:encrypted_hot_seed][:cipher_nonce] = base58(nonce)

# Finally, generate the ciphertext of the hot seed.
ciphertext = RbNaCl::SecretBox.new(key).encrypt(nonce, hot_seed)
client[:encrypted_hot_seed][:ciphertext] = base58(ciphertext)


# Now generate server data


server_wallet = MultiWallet.generate [:warm]
server[:warm_seed] = server_wallet.trees[:warm].to_serialized_address(:private)

server_wallet.import(client[:public_addresses])

#server[:address] = {
  #:path => path,
  #:hash => server_node.p2sh_address
#}

# create block chain from scratch, then disburse funds
# to a few pay-to-pubkey-hash addresses.
test_chain = BitVaultTests::Mockchain.new

keypair_1, keypair_2, keypair_3 = (1..3).map do
  key = Bitcoin::Key.new
  key.generate
  key
end

bootstrap_transaction = test_chain.transaction(
  keypair_1.addr => (test_chain.mining_fee / 2),
  keypair_2.addr => (test_chain.mining_fee / 4),
  keypair_3.addr => (test_chain.mining_fee / 8),
)

#network[:bootstrap_transaction] = bootstrap_transaction


# Create a p2sh address for funding the wallet
path = "/m/1/0/1"
server_node = server_wallet.path(path)
server[:funding_path] = path
server[:funding_address] = funding_address = server_node.p2sh_address


# Spend the outputs from the bootstrapping transaction in
# two separate payments to the ps2h address.

value = 0
outputs = bootstrap_transaction.outputs.slice(0,2)
outputs.each do |output|
  value += output.value
end

funding_transaction_1 = Builder.build_tx do |t|
  t.input do |i|
    i.prev_out bootstrap_transaction
    i.prev_out_index 0
    i.signature_key keypair_1
  end

  t.input do |i|
    i.prev_out bootstrap_transaction
    i.prev_out_index 1
    i.signature_key keypair_2
  end

  t.output do |o|
    o.value (value)
    o.script do |s|
      s.recipient funding_address
    end
  end
end

value = bootstrap_transaction.outputs[2].value
funding_transaction_2 = Builder.build_tx do |t|
  t.input do |i|
    i.prev_out bootstrap_transaction
    i.prev_out_index 2
    i.signature_key keypair_3
  end

  t.output do |o|
    o.value value
    o.script do |s|
      s.recipient funding_address
    end
  end
end

network[:funding_transaction_1] = funding_transaction_1
network[:funding_transaction_2] = funding_transaction_2


# Create a pay-to-pubkey-hash address to receive an outgoing payment
vendor_key = Bitcoin::Key.new
vendor_key.generate


value = (test_chain.mining_fee / 8) - 10_000

outgoing_transaction = Builder.build_tx do |t|
  t.output do |o|
    o.value value
    o.script do |s|
      s.recipient vendor_key.addr
    end
  end
end


# the wallet node creates an input, adds it to the transaction, and
# prepares the sig_hash.
txin = server_node.add_input outgoing_transaction,
  :prev => funding_transaction_2, :index => 0


network[:outgoing_transaction] = outgoing_transaction
puts outgoing_transaction.to_json









#puts JSON.pretty_generate(data)

File.open "test/data/script.json", "w" do |f|
  f.puts JSON.pretty_generate(data)
end

