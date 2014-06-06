project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
$:.unshift "#{project_root}/lib"

API_HOST = 'http://localhost:8999'
require "bitvault"

## API discovery
#
# The BitVault server provides a JSON description of its API that allows
# the client to generate all necessary resource classes at runtime.

client = BitVault::Patchboard.client
## User management
#
# The create action returns a User Resource which has:
#
# * action methods (get, update, reset)
# * attributes (email, first_name, etc.)
# * associated resources (applications)

user = client.users.create(
  email: 'julian@bitvault.io',
  first_name: 'Julian',
  last_name: 'Vergel de Dios',
  password: 'terrible_secret'
)

client = BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret')
user = client.user

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
  name: 'bitcoin_app',
  callback_url: 'http://someapp.com/callback'
)

## Wallets
#
# Wallets belong to applications, not directly to users. They require
# a passphrase to be provided on creation.

wallet = app.wallets.create(passphrase: 'very insecure', name: 'my funds')

# An application's wallet collection is enumerable

wallet = app.wallets.each { |wallet| pp wallet }

# And acts as a hash with names as keys

wallet = app.wallets['my funds']

# The passphrase is required to unlock the wallet before you can
# perform any transactions with it.

wallet.unlock('very insecure')

## Accounts
#
# Wallets can have multiple accounts, each represented by a path in the
# MultiWallet's deterministic trees.

account = wallet.accounts.create(name: 'office supplies')

## Payments
#
# Sending payments

# Creating addresses for receiving payments
# This is a BIP 16 "Pay to Script Hash" address, where the script in question
# is a BIP 11 "multisig".

payment_address = account.addresses.create

# TODO: Additional method "prepare" to obtain unsigned transaction for inspection
payment = account.pay([{ address: payment_address.string, amount: 20_000 }])

## Transfers

account_1 = wallet.accounts['rubber bands']
account_2 = wallet.accounts.create(name: 'travel expenses')

wallet.transfer(amount: 10_000, source: account_1, destination: account_2)