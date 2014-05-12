require_relative "setup"

## API discovery
#
# The BitVault server provides a JSON description of its API that allows
# the client to generate all necessary resource classes at runtime.

client = BitVault::Client.discover

## User management
#
# The create action returns a User Resource which has:
#
# * action methods (get, update, reset)
# * attributes (email, first_name, etc.)
# * associated resources (applications)

user = client.users.create(
  email: 'matthew@bitvault.io',
  first_name: 'Matthew',
  last_name: 'King',
  password: 'incredibly_secure'
)

user.update(first_name: 'Matt')

## Application management

## Fetch applications
#
# If the applications collection is not populated, it will be fetched from the
# server. The cached version will be used if it is already loaded. A refresh can
# be triggered by passing it as an option to the action.

user.applications
user.applications(refresh: true)

## Create an application.
#
# The optional callback_url attribute specifies a URL where BitVault
# can POST event information such as confirmed transactions.

app = user.applications.create(
  name: 'bitcoin_emporium',
  callback_url: 'https://api.bitcoin-emporium.io/events'
)

app.update(name: 'bitcoin_mega_emporium')

# Existing applications can also be fetched using a known token

APP_TOKEN = 'abcdef123456'
app = user.applications.authenticate(APP_TOKEN)

## Wallets
#
# Wallets belong to applications, not directly to users. They require
# a passphrase to be provided on creation.

wallet = app.wallets.create(passphrase: 'super_secure', name: 'smurfs')

# An application's wallet collection is enumerable

wallet = app.wallets.each { |wallet| pp wallet }

# And acts as a hash with names as keys

wallet = app.wallets['smurfs']

# The passphrase is required to unlock the wallet before you can
# perform any transactions with it.

wallet.authorize('super_secure')

## Accounts
#
# Wallets can have multiple accounts, each represented by a path in the
# MultiWallet's deterministic trees.

account = wallet.accounts.create(name: 'office supplies')
account.update(name: 'rubber bands')

## Payments
#
# Sending payments

payment = account.pay(payees: { 'address1' => 10_000, 'address2' => 20_000 })

# Creating addresses for receiving payments
# This is a BIP 16 "Pay to Script Hash" address, where the script in question
# is a BIP 11 "multisig".

address = account.addresses.create

## Transfers

account_1 = wallet.accounts['rubber bands']
account_2 = wallet.accounts.create(name: 'travel expenses')

wallet.transfer(amount: 10_000, source: account_1, destination: account_2)