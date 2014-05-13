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
encrypted_seed = {
  "salt" => "FPX1ZBkCLTzxMTuVzy856m",
  "iterations" => 100000,
  "nonce" => "PRa5MVMjLzX3qKBJGr7PP7wGEqUQQ7suQ",
  "ciphertext" => "5VhRdNdneQU2qykUJGbr3aDP5jt2MRHD795jHNniCzraTRbNyukuh1ZcyjwyvaKPxwca6kRYfsuEqPRAjHtV9g6hByehYyzmG1GYyRxWhu51w2YYtHzGeV1Ev5G6bZprM6SC5i8caob7DGnoAsFxYeygvxAjAFQ77ABZRqXDKihwjr"
}

# Retrieve the user resource

user = client.resources.user(user_url).get

# Supply the client with the authentication credential

client.context.api_token = api_token

# Retrieve application

application = user.applications.list[0]

# FIXME: Do we need to do this? It currently makes no difference
#application = application.get

# Retrieve wallet

log "Wallet list", application.wallets.list
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


## Retrieve and use the newly created wallet for further actions.

# FIXME: why do we do this? It currently doesn't make a difference
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


