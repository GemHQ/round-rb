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


# Create a user
#
# The objects in `client.resources` are resource instances created at
# discovery-time.  Each has action methods defined based on the JSON
# API definition.  Action methods perform the actual HTTP requests
# and wrap the results in further resource instances when appropriate.

users = client.resources.users

user = users.create(
  :email => "matthew@bitvault.io",
  :first_name => "Matthew",
  :last_name => "King",
  :password => "incredibly secure"
)

log "User", user

# The create action returned a User Resource which has:
#
# * action methods (get, update, reset)
# * attributes (email, first_name, etc.)
# * associated resources (applications)


## Simulate a later session

client = BV.spawn

# Supply the client with the user password, required to manage the user
# and its applications.  The context class used here determines which
# credential to use based on the authorization scheme.

client.context.password = "incredibly secure"

# Retrieve the user resource

user = client.resources.user(user.url).get


## Update some attributes for the user

user = user.update(:first_name => "Matt")
log "User updated", user


## Create an application.
#
# Wallets belong to applications, not directly
# to users. The optional callback_url attribute specifies a URL where BitVault
# can POST event information such as confirmed transactions.

application = user.applications.create(
  :name => "bitcoin_emporium",
  :callback_url => "https://api.bitcoin-emporium.io/events"
)

log "Application", application

# Applications use API tokens for authentication, rather than
# requiring the user password.  Tokens can be reset easily,
# password resets pose a major inconvenience to the user.

# Supply the client with the authentication credential
client.context.api_token = application.api_token

# List and retrieve applications
log "Application list", user.applications.list
log "Retrieved application", application.get

updated = application.update(:name => "bitcoin_extravaganza")


## Reset or delete the application
#
# At time of writing, the server is using mocked data, so these actions
# do not affect the rest of the script.

reset = application.reset

log "Application reset", {
  :previous_token => application.api_token,
  :new_token => reset.api_token
}

result = application.delete
log "Application delete response status", result.response.status


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

log "Wallet list", application.wallets.list


## Retrieve and use the newly created wallet for further actions.

wallet = wallet.get


## Create an account within a wallet
#
# Wallets can have multiple accounts, each represented by a path in the
# MultiWallet's deterministic trees.

account = wallet.accounts.create :name => "office supplies"

log "Account", account
log "Account list", wallet.accounts.list

## Prove you can retrieve and use the newly created account
account = account.get


log "Account updated", account.update(:name => "rubber bands")


## Generate an address where others can send payments.
#
# This is a BIP 16 "Pay to Script Hash" address, where the script in question
# is a BIP 11 "multisig".

incoming_address = account.addresses.create

log "Payment address", incoming_address


## Request a payment of bitcoins from this account to someone else's address.

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

## Reconstruct the transaction for signing.
#
# The unsigned payment record contains all the information needed for the
# client to reconstruct and sign the Bitcoin transaction without needing to
# search the blockchain for the inputs' previous transactions.  For the
# highest achievable level of security, of course, clients must search an
# independently maintained blockchain for the previous transactions.
#
# In practice, some users may not judge this to be necessary.  So long as the 
# client verifies all the output addresses and values are correct, the
# multiple-signature approach makes it impossible for a cosigning service to
# steal bitcoins by this approach.
#
# The only realistic attack by the cosigning
# service would be to falsify the values of the inputs, which cannot plausibly
# benefit the service.  If the selected inputs do not contain enough bitcoin
# to fund the transaction, nothing happens except a waste of everybody's time;
# the transaction is invalid and the Bitcoin network will reject it.
#
# If the selected outputs contain more substantially bitcoin than required to
# fund the transaction, the service could report lower values, then calculate
# the amount to send to the change address based on the falsified inputs.  But
# the only result of this would be to grant an exorbitant transaction fee to
# whichever miner solves the next block.

transaction = BitVault::Bitcoin::Transaction.data(unsigned_payment)


## Sign the transaction inputs
#
# Transaction inputs are really references to the outputs of previous
# transactions.  All bitcoins belonging to a BitVault account were paid
# to P2SH-Multisig addresses generated by the three-tree MultiWallet
# described earlier.  Thus the client must know the wallet path used
# to generate the address for each previous output.  We include this
# in the output metadata supplied as a part of each transaction input.
#
# We include the wallet path in the output for the change address, as well,
# so that the client can verify the address belongs to the correct wallet.
#
# Given an input and the corresponding wallet path, the client selects
# the correct "primary" private key and signs the input.

unless client_wallet.valid_output?(transaction.outputs.last)
  raise "bad change address"
end


## Send the input signatures back to the server
#
# When the server receives the signatures for a transaction, it will verify
# them and check which of the MultiWallet private keys was used for each.
# We expect the "primary" key to be used for all normal transactions;
# when the "backup" key is used, we take that as a signal that something
# has gone wrong, and we impose account restrictions until we have
# communicated with the wallet owner.
#
# After verifying all the input signatures, the server signs each with its
# own private "cosigner" keys, relays the transaction to the network,
# then sends the fully signed transaction record back to the client.

signed_payment = unsigned_payment.sign(
  :transaction_hash => transaction.base58_hash,
  :inputs => client_wallet.signatures(transaction)
)

log "Signed payment", signed_payment


# The client will then be able to check the confirmation status of the signed
# payment.  Exact API to be determined.  To mitigate the need for polling, the
# service will post transaction statuses to the application's callback_url,
# if supplied.


## Transfer money between two accounts in the same wallet

unsigned_transfer = wallet.transfers.create(
  :value => 16_000,
  :memo => "running low",
  :source => "URL of source account goes here",
  :destination => "URL of destination account goes here"
)

log "Unsigned transfer", unsigned_transfer

## Reconstruct the transaction for signing

transaction = BitVault::Bitcoin::Transaction.data(unsigned_payment)

unless client_wallet.valid_output?(transaction.inputs.first.output)
  raise "bad destination address"
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

# Signature verification doesn't work currently, because you need to have
# the full previous output for each input, which requires querying the
# blockchain in some manner.
#
#transaction = BitVault::Bitcoin::Transaction.data(signed_transfer)
#pp transaction.validate_script_sigs

## List the transactions for an account

list = account.transactions.list

log "Transactions list", list

## Retrieve an individual transaction

transaction = list[0].get

log "Transaction get", transaction


