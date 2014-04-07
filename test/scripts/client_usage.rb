require "term/ansicolor"
String.send :include, Term::ANSIColor

require_relative "setup"

include BitVault::Encodings

PassphraseBox = BitVault::Crypto::PassphraseBox
MultiWallet = BitVault::Bitcoin::MultiWallet


# API discovery:
#
# The BitVault server provides a JSON description of its API that allows
# the client to generate all necessary resource classes at runtime.
# We initialize the BitVault client with a block that returns an object
# that will be used as a "context", a place to store needful things.
# At present, the only requirement for a context object is that it
# implements a method named `authorizer`, which must return a credential
# for use in the HTTP Authorization headers.

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }

# Create a "sub-client" with its own context
client = BV.spawn

# The objects in `client.resources` are resource instances created at
# discovery-time.  Each has action methods defined based on the JSON
# API definition.  Action methods perform the actual HTTP requests
# and wrap the results in further resource instances when appropriate.

users = client.resources.users

# Create a user

user = users.create(
  :email => "matthew@bitvault.io",
  :first_name => "Matthew",
  :last_name => "King",
  :password => "incredibly secure"
)

log "User", user


# Supply the client with the user password, required to operate
# on the user and its applications.
client.context.password = "incredibly secure"

# The create action returned a User Resource which has:
#
# * action methods (get, update, reset)
# * attributes (email, first_name, etc.)
# * associated resources (applications)


# Update some attributes for the user

user = user.update(:first_name => "Matt")
log "User updated", user


# Create an application

application = user.applications.create(
  :name => "bitcoin_emporium",
  :callback_url => "https://api.bitcoin-emporium.io/events"
)

log "Application", application

# Supply the client with the authentication credential
client.context.api_token = application.api_token

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


# A MultiWallet encapsulates any number of hierarchical deterministic
# wallet trees (BIP 32).  Some of the trees may be public-key only.
#
# From a high-level point of view, a BitVault wallet consists of three
# trees: the primary, the cosigner, and the backup.  The primary and
# backup trees are owned by the user, the cosigner tree by BitVault.
# "Owned" here means "knows the root private key".  The root public
# keys for all three trees are, of course, public.  The root private
# key for the backup tree should be stored offline.
#
# BitVault uses all three public trees to generate multisig payment addresses
# for a wallet.  To spend bitcoins paid to such an address requires
# two signatures.  Under normal circumstances, these signatures will be
# derived from the primary and cosigner trees.


# Generate a MultiWallet with random seeds

new_wallet = MultiWallet.generate [:primary, :backup]
primary_seed = new_wallet.trees[:primary].to_serialized_address(:private)

# Encrypt the primary seed using a [key derived from a] passphrase.
passphrase = "wrong pony generator brad"
encrypted_seed = PassphraseBox.encrypt(passphrase, primary_seed)

wallet = application.wallets.create(
  :name => "my favorite wallet",
  :network => "bitcoin_testnet",
  :backup_address => new_wallet.trees[:backup].to_serialized_address,
  :primary_address => new_wallet.trees[:primary].to_serialized_address,
  :primary_seed => encrypted_seed
)

log "Wallet", wallet

# Use the server's response data to construct a MultiWallet, as
# would be done in any subsequent interactions.  It will be
# used later in this script to verify and sign a transaction.

primary_seed = PassphraseBox.decrypt(passphrase, wallet.primary_seed)
client_wallet = MultiWallet.new(
  :private => {
    :primary => primary_seed
  },
  :public => {
    :cosigner => wallet.cosigner_address,
    :backup => wallet.backup_address
  }
)

log "Wallet list", application.wallets.list

# Prove that you can retrieve and use the newly created wallet
wallet = wallet.get


# Wallets can have multiple accounts, each represented by a path in the
# MultiWallet's deterministic trees.

# Create an account within a wallet

account = wallet.accounts.create :name => "office supplies"

log "Account", account
log "Account list", wallet.accounts.list

# Prove you can retrieve and use the newly created account
account = account.get


log "Account updated", account.update(:name => "rubber bands")



# Generate an address for others to send payments to 
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



