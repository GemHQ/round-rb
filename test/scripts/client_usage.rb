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

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn

# Create a user
user = client.resources.users.create(
  :email => "matthew-#{rand(10000)}@mail.com",
  :first_name => "Matthew",
  :last_name => "King"
)
log "User", user

# Tell the client about the authentication token
client.context.api_token = user.api_token

# Generate a wallet with new seeds
client_wallet = BitVault::Bitcoin::MultiWallet.generate [:hot, :cold]

# Derive a secret key from a passphrase
passphrase = BitVault::Client::Passphrase.new "this is not a secure passphrase"
key, salt = passphrase.key, passphrase.salt

# Encrypt the hot seed with the secret key
nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
hot_seed = client_wallet.trees[:hot].to_serialized_address(:private)
ciphertext = RbNaCl::SecretBox.new(key).encrypt(nonce, hot_seed)


wallet = user.wallets.create(
  :name => "my favorite wallet",
  :network => "bitcoin_testnet",
  :cold_address => client_wallet.trees[:cold].to_serialized_address,
  :hot_address => client_wallet.trees[:hot].to_serialized_address,
  :hot_seed => {
    :passphrase_salt => base58(salt),
    :cipher_nonce => base58(nonce),
    :ciphertext => base58(ciphertext),
  }
)

log "Wallet", wallet

client_wallet.import :warm => wallet.warm_address

# Use the values returned by the server to construct the wallet,
# because it's presently serving canned values.

passphrase = "wrong pony generator brad"
salt = decode_base58(wallet.hot_seed.passphrase_salt)
key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
  passphrase, salt,
  10_000, # number of iterations
  32      # key length in bytes
)
nonce = decode_base58(wallet.hot_seed.cipher_nonce)
ciphertext = decode_base58(wallet.hot_seed.ciphertext)
hot_seed = RbNaCl::SecretBox.new(key).decrypt(nonce, ciphertext)



client_wallet = BitVault::Bitcoin::MultiWallet.new(
  :full => {
    :hot => hot_seed
  },
  :public => {
    :warm => wallet.warm_address,
    :cold => wallet.cold_address
  }
)

wallet = wallet.get

log "Wallet get", wallet

account = wallet.accounts.create :name => "office supplies"
log "Account", account

list = wallet.accounts.list

log "Account list", wallet.accounts.list


account = account.get

log "Account get", account

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
  signature = base58(node.sign(:hot, input.binary_sig_hash))
  #pp :path => path, :sig_hash => input.sig_hash, :signature => signature
end

signed_payment = unsigned_payment.sign(
  :transaction_hash => transaction.base58_hash,
  :signatures => signatures
)

log "Signed payment", signed_payment

exit
signed_transaction = BitVault::Bitcoin::Transaction.data(signed_payment)
signed_transaction.validate_signatures # vaporware



