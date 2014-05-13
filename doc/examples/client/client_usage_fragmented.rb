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

# Retrieve the account
account = wallet.accounts.list[0]


## Transfer money between two accounts in the same wallet

unsigned_transfer = wallet.transfers.create(
  :value => 16_000,
  :memo => "running low",
  :source => "URL of source account goes here",
  :destination => "URL of destination account goes here"
)

log "Unsigned transfer", unsigned_transfer

## Reconstruct the transaction for signing

transaction = BitVault::Bitcoin::Transaction.data(unsigned_transfer)

unless client_wallet.valid_output?(transaction.inputs.first.output)
  raise "bad source address"
end

unless client_wallet.valid_output?(transaction.outputs.last)
  raise "bad destination address"
end

signatures = client_wallet.signatures(transaction)

signed_transfer = unsigned_transfer.sign(
  :transaction_hash => transaction.base58_hash,
  :inputs => client_wallet.signatures(transaction)
)

log "Signed transfer", signed_transfer

# Because the client is not (yet) querying the block chain, it cannot
# verify the input signatures.  When we implement block-chain querying,
# transaction verification will look like this:
#
#   transaction = BitVault::Bitcoin::Transaction.data(signed_transfer)
#   report = transaction.validate_script_sigs
#   if report[:valid] == false
#     pp report[:errors]
#   end
#
# It is not strictly necessary for the client to verify the signatures.
# The only rationale for doing so would be to detect an error in the
# server's signatures.  Such an error would make the transaction invalid,
# but would not put any bitcoin at risk.


## List the transactions for an account

list = account.transactions.list

log "Transactions list", list

## Retrieve an individual transaction

transaction = list[0].get

log "Transaction get", transaction


