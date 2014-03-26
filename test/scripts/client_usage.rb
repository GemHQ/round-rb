require "term/ansicolor"
String.send :include, Term::ANSIColor

require_relative "setup"

include BitVault::Bitcoin::Encodings

# colored output to make it easier to see structure
def log(message, data)
  if data.is_a? String
    puts "#{message.green.underline} => #{data.dump.cyan}"
  else
    puts "#{message.green.underline} => #{JSON.pretty_generate(data).cyan}"
  end
  puts
end

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn

# Create a user
user = client.resources.users.create :email => "matthew-#{rand(10000)}@mail.com"
log "User", user.attributes

# Tell the client about the authentication token
client.context.api_token = user.api_token

# Generate a wallet with new seeds
wallet = BitVault::Bitcoin::MultiWallet.generate [:hot, :cold]

# Derive a secret key from a passphrase
passphrase = BitVault::Client::Passphrase.new "this is not a secure passphrase"
key, salt = passphrase.key, passphrase.salt

# Encrypt the hot seed with the secret key
nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
hot_seed = wallet.trees[:hot].to_serialized_address(:private)
ciphertext = RbNaCl::SecretBox.new(key).encrypt(nonce, hot_seed)


wallet = user.wallets.create(
  :name => "my favorite wallet",
  :network => "bitcoin_testnet",
  :cold_address => wallet.trees[:cold].to_serialized_address,
  :hot_address => wallet.trees[:hot].to_serialized_address,
  :hot_seed => {
    :passphrase_salt => base58(salt),
    :cipher_nonce => base58(nonce),
    :ciphertext => base58(ciphertext),
  }
)

log "Wallet", wallet.attributes
puts

account = wallet.accounts.create :name => "office supplies"
log "Account", account.attributes

list = wallet.accounts.list

log "Account list", wallet.accounts.list

# get an address that others can send payments to 
address = account.addresses.create

log "Payment address", address[:string]

unsigned_payment = account.payments.create(
  :outputs => [
    {
      :amount => 600_000,
      :payee => {:address => ""}
    }
  ]
)
log "Unsigned payment data from JSON", JSON.parse(unsigned_payment.json)

blob = decode_base58(unsigned_payment.serialized)
tx = Bitcoin::Protocol::Tx.new(blob)
log "Unsigned payment data from serialized", tx

log "sighashes", unsigned_payment.attributes.inputs



