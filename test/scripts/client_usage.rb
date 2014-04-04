require "term/ansicolor"
String.send :include, Term::ANSIColor

require_relative "setup"

include BitVault::Bitcoin::Encodings

# colored output to make it easier to see structure
def log(message, data)
  if data.is_a? String
    puts "#{message.yellow.underline} => #{data.dump.cyan}"
  else
    begin
      puts "#{message.yellow.underline} => #{JSON.pretty_generate(data).cyan}"
    rescue
      puts "#{message.yellow.underline} => #{data.inspect.cyan}"
    end
  end
  puts
end

#def log(message, data)
  #puts "#{message} ---\n#{JSON.pretty_generate data}"
  #puts
#end

#####

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn

# Create a user
user = client.resources.users.create(
  :email => "matthew@bitvault.io",
  :first_name => "Matthew",
  :last_name => "King"
)
log "User", user

# Tell the client about the authentication token
client.context.api_token = user.api_token

# Update a user attribute

updated = user.update(:first_name => "Matt")
log "User updated", updated


reset = user.reset

log "User reset", {:previous_token => user.api_token,
  :new_token => reset.api_token}


# Application actions

application = user.applications.create(
  :name => "bitcoin_emporium"
)

log "Application", application

# Verify that you can list applications
list = user.applications.list

# Verify that you can retrieve the application
application = application.get

updated = application.update(:name => "bitcoin_extravaganza")

reset = application.reset

log "Application reset", {:previous_token => application.api_token,
  :new_token => reset.api_token}

# At time of writing, the server is using mocked data, so this
# doesn't actually delete anything.
result = application.delete
log "Application delete response status", result.response.status






# Generate a MultiWallet with random seeds
client_wallet = BitVault::Bitcoin::MultiWallet.generate [:primary, :backup]

# Derive a secret key from a passphrase
passphrase = BitVault::Client::Passphrase.new "this is not a secure passphrase"
key, salt = passphrase.key, passphrase.salt

# Encrypt the primary seed with the secret key
nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
primary_seed = client_wallet.trees[:primary].to_serialized_address(:private)
ciphertext = RbNaCl::SecretBox.new(key).encrypt(nonce, primary_seed)


wallet = user.wallets.create(
  :name => "my favorite wallet",
  :network => "bitcoin_testnet",
  :backup_address => client_wallet.trees[:backup].to_serialized_address,
  :primary_address => client_wallet.trees[:primary].to_serialized_address,
  :primary_seed => {
    :passphrase_salt => base58(salt),
    :cipher_nonce => base58(nonce),
    :ciphertext => base58(ciphertext),
  }
)

log "Wallet", wallet

client_wallet.import :cosigner => wallet.cosigner_address

# Use the values returned by the server to construct the wallet,
# because it's presently serving canned values.

passphrase = "wrong pony generator brad"
salt = decode_base58(wallet.primary_seed.passphrase_salt)
key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
  passphrase, salt,
  10_000, # number of iterations
  32      # key length in bytes
)
nonce = decode_base58(wallet.primary_seed.cipher_nonce)
ciphertext = decode_base58(wallet.primary_seed.ciphertext)
primary_seed = RbNaCl::SecretBox.new(key).decrypt(nonce, ciphertext)



client_wallet = BitVault::Bitcoin::MultiWallet.new(
  :full => {
    :primary => primary_seed
  },
  :public => {
    :cosigner => wallet.cosigner_address,
    :backup => wallet.backup_address
  }
)

# Verify that you can retrieve the newly created wallet
wallet = wallet.get

# Verify that you can list wallets
list = user.wallets.list


account = wallet.accounts.create :name => "office supplies"
log "Account", account

list = wallet.accounts.list

log "Account list", wallet.accounts.list

account = account.get

log "Account get", account

updated = account.update(:name => "staples")

log "Account updated", updated


# get an address that others can send payments to 
incoming_address = account.addresses.create

log "Payment address", incoming_address

# Request a payment to someone else's address

other_key = Bitcoin::Key.new
other_key.generate
other_address = other_key.addr

unsigned_payment = account.payments.create(
  :outputs => [
    {
      :amount => 600_000,
      :payee => {:address => other_address}
    }
  ]
)

log "Unsigned payment", unsigned_payment
transaction = BitVault::Bitcoin::Transaction.data(unsigned_payment)
#log "Reconstructed tx", transaction


signatures = transaction.inputs.map do |input|
  path = input.output.metadata.wallet_path
  node = client_wallet.path(path)
  signature = base58(node.sign(:primary, input.binary_sig_hash))
  #pp :path => path, :sig_hash => input.sig_hash, :signature => signature
end

signed_payment = unsigned_payment.sign(
  :transaction_hash => transaction.base58_hash,
  :signatures => signatures
)

log "Signed payment", signed_payment


exit
# verify that the signed transaction has correct script_sigs
signed_transaction = BitVault::Bitcoin::Transaction.data(signed_payment)
signed_transaction.validate_signatures # vaporware



