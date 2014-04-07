require "term/ansicolor"
String.send :include, Term::ANSIColor

require_relative "setup"

include BitVault::Bitcoin::Encodings

PassphraseBox = BitVault::Crypto::PassphraseBox
MultiWallet = BitVault::Bitcoin::MultiWallet


BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn

# Create a user
user = client.resources.users.create(
  :email => "matthew@bitvault.io",
  :first_name => "Matthew",
  :last_name => "King"
)
log "User", user

# Supply the client with the token needed to authenticate further requests.

client.context.api_token = user.api_token

# Update a user attribute

updated = user.update(:first_name => "Matt")
log "User updated", updated


# Reset the authentication token.
# This has no effect on the rest of this script because the API
# is currently suppling mock data.

reset = user.reset

log "User reset", {:previous_token => user.api_token,
  :new_token => reset.api_token}


# Create an application

application = user.applications.create(
  :name => "bitcoin_emporium",
  :callback_url => "https://api.bitcoin-emporium.io/events"
)

log "Application", application

# List and retrieve applications
log "Application list", user.applications.list
log "Retrieved application", application.get

updated = application.update(:name => "bitcoin_extravaganza")

reset = application.reset

log "Application reset", {:previous_token => application.api_token,
  :new_token => reset.api_token}

# At time of writing, the server is using mocked data, so this
# doesn't actually delete anything.
result = application.delete
log "Application delete response status", result.response.status


# Generate a MultiWallet with random seeds
client_wallet = MultiWallet.generate [:primary, :backup]
primary_seed = client_wallet.trees[:primary].to_serialized_address(:private)

# Encrypt the primary seed using a [key derived from a] passphrase.
passphrase = "this is not a secure passphrase"
encrypted_seed = PassphraseBox.encrypt(passphrase, primary_seed)

wallet = user.wallets.create(
  :name => "my favorite wallet",
  :network => "bitcoin_testnet",
  :backup_address => client_wallet.trees[:backup].to_serialized_address,
  :primary_address => client_wallet.trees[:primary].to_serialized_address,
  :primary_seed => encrypted_seed
)

log "Wallet", wallet

client_wallet.import :cosigner => wallet.cosigner_address

# Use the server's response data to construct the wallet,
# because it's presently serving canned values.
primary_seed = PassphraseBox.decrypt(
  "wrong pony generator brad", wallet.primary_seed
)



client_wallet = MultiWallet.new(
  :private => {
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

payee = Bitcoin::Key.new
payee.generate
payee_address = payee.addr

unsigned_payment = account.payments.create(
  :outputs => [
    {
      :amount => 600_000,
      :payee => {:address => payee_address}
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



