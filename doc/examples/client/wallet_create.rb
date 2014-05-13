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

# Retrieve the user resource

user = client.resources.user(user_url).get

# Supply the client with the authentication credential

client.context.api_token = api_token

# Retrieve application

application = user.applications.list[0]
# FIXME: Do we need to do this? It currently makes no difference
#application = application.get


## Generate a MultiWallet with random seeds
#
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

new_wallet = MultiWallet.generate [:primary, :backup]
primary_seed = new_wallet.trees[:primary].to_serialized_address(:private)


## Encrypt the primary seed using a passphrase-derived key

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

log "Wallet list", application.wallets.list
