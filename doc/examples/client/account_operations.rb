require_relative "setup"

include BitVault::Encodings

PassphraseBox = BitVault::Crypto::PassphraseBox
MultiWallet = BitVault::Bitcoin::MultiWallet


## API discovery
#
# The BitVault server provides a JSON description of its API that allows
# the client to generate all necessary resource classes at runtime.
# We initialize the BitVault client with a block that returns an object
# that will be used as a "context", a place to store needful things.
# At present, the only requirement for a context object is that it
# implements a method named `authorizer`, which must return a credential
# for use in the HTTP Authorization headers.

service_url = ARGV[0] || "http://localhost:8999/"
BV = BitVault::Client.discover(service_url) { BitVault::Client::Context.new }

## Create a "sub-client" with its own context

client = BV.spawn

# Supply the client with the user password, required to manage the user
# and its applications.  The context class used here determines which
# credential to use based on the authorization scheme.

# Data from the client's database
client.context.password = "incredibly_secure"
user_url = "http://localhost:8999/users/Kw8aTuNfh6ZXKpq1CpmRMf"
api_token = "9ZmwP5nDu3p59xMqELqVrnedXkYG4vKqQrssHxAs8chi"
passphrase = "wrong pony generator brad"

# Retrieve the user resource

user = client.resources.user(user_url).get

# Supply the client with the authentication credential

client.context.api_token = api_token

# Retrieve application

application = user.applications.list[0]

# FIXME: Do we need to do this? It currently makes no difference
#application = application.get

# Retrieve wallet

# FIXME: I  just guessed this, double-check that it's correct--DLL
wallet = application.wallets.list[0]

## Use the server's response data to construct a MultiWallet
#
# This models what an application would do in any subsequent interactions.
# The MultiWallet will be used later in this script to verify and sign a
# transaction.

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

## Create an account within a wallet
#
# Wallets can have multiple accounts, each represented by a path in the
# MultiWallet's deterministic trees.

log "Account list", wallet.accounts.list

account = wallet.accounts.list[0]

log "Account updated", account.update(:name => "rubber bands")
