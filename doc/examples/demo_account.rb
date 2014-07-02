require_relative "setup"

if File.exists? saved_file
  data = YAML.load_file saved_file
  addresses = data[:nodes]
  puts
  puts <<-MESSAGE
  Settings from a previous run of this script are in #{saved_file}.
  If you have not already funded that wallet, you can remove the file.
  Otherwise, fund these addresses:

  #{addresses.map {|address| address[:string]}.join("\n  ")}

  then run demo_payment.rb
  You can check the state of transactions for the addresses at:

  #{addresses.map {|address| 'http://tbtc.blockr.io/address/info/' + address[:string]}.join("\n  ")}
  MESSAGE
  puts
  exit
end

## Create an unauthed client

client = BitVault::Patchboard.client

# Create a user
#
# The objects in `client.resources` are resource instances created at
# discovery-time.  Each has action methods defined based on the JSON
# API definition.  Action methods perform the actual HTTP requests
# and wrap the results in further resource instances when appropriate.

email = "matthew-#{Time.now.to_i}@bitvault.io"

user = client.users.create(
  :email => email,
  :first_name => "Matthew",
  :last_name => "King",
  :password => "incredibly_secure"
)
log "Create a user with", mask(user, :email, :first_name, :last_name)

# The create action returned a User Resource which has:
#
# * action methods (get, update, reset)
# * attributes (email, first_name, etc.)
# * associated resources (applications)


## Simulate a later session

client = BitVault::Patchboard.authed_client(email: email, password: "incredibly_secure")

# Retrieve the user resource

user = client.user

## Create an application.
#
# Wallets belong to applications, not directly
# to users. The optional callback_url attribute specifies a URL where BitVault
# can POST event information such as confirmed transactions.

application = user.applications.create(
  :name => "bitcoin_emporium",
  :callback_url => "https://api.bitcoin-emporium.io/events"
)

log "Created an application for the user", mask(application, :name, :api_token, :callback_url)

# Applications use API tokens for authentication, rather than
# requiring the user password.  Tokens can be reset easily,
# password resets pose a major inconvenience to the user.

# Spawn new client with the authentication credential

client = BitVault::Patchboard.authed_client(app_url: application.url, api_token: application.api_token)

# List applications
list = user.applications
log "List the user applications", (list.map do |name, app|
  mask(app, :name, :api_token, :callback_url)
end)


## Reset or delete the application
#

# reset = application.reset

# log "Reset an application's api token", {
#   :previous_token => application.api_token,
#   :new_token => reset.api_token
# }

# client.context.set_token(reset.api_token)


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

passphrase = "wrong pony generator brad"
wallet = application.wallets.create(name: 'my favorite wallet', passphrase: passphrase)
primary_seed = wallet.multiwallet.trees[:primary].to_serialized_address(:private)

log "Create a co-signing wallet for an application", mask(
  wallet,
  :name, :network,
  :backup_public_seed, :primary_public_seed, :cosigner_public_seed
)

## Create an account within a wallet
#
# Wallets can have multiple accounts, each represented by a path in the
# MultiWallet's deterministic trees.

account = wallet.accounts.create :name => "office supplies"

log "Create an account within a wallet", mask(account, :name, :path, :balance, :pending_balance)



## Generate an address where others can send payments.
#
# This is a BIP 16 "Pay to Script Hash" address, where the script in question
# is a BIP 11 "multisig".

incoming_addresses = []
6.times do
  incoming_addresses << account.addresses.create
end

log "Generate a Bitcoin address to fund the account", (incoming_addresses.map do |address|
  mask(address, :path, :string) end
)



# Until funded the account can't be used to generate payments or transfers to
# other accounts in the wallet.

puts "Writing wallet information to #{saved_file} for use in next test."

record = {
  app_url: application.url,
  api_token: client.context.api_token,
  wallet: {url: wallet.url, name: wallet.name, passphrase: passphrase},
  account: {url: account.url, name: account.name},
  nodes: incoming_addresses.map { |address|
    {
      path: address.path,
      string: address.string
    }
  }
}
File.open saved_file, "w" do |f|
  f.puts record.to_yaml
end

puts <<-MESSAGE
  Fund these addresses from a testnet faucet, so that you can make payments or transfers:

  #{incoming_addresses.map {|address| address.string}.join("\n  ")}

  Then you can run demo_payment.rb

  Suggested faucet:  http://faucet.xeno-genesis.com
  Once the transaction is confirmed (with 6 blocks) run demo_payment.rb

  You can check the state of transactions for the addresses at:
  #{incoming_addresses.map {|address| 'http://tbtc.blockr.io/address/info/' + address.string}.join("\n  ")}
MESSAGE


