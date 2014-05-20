require_relative "setup"

require "term/ansicolor"
String.send :include, Term::ANSIColor

# colored output to make it easier to see structure
def log(message, data=nil)
  if data.is_a? String
    puts "#{message.yellow} => #{data.dump.cyan}"
  elsif data.nil?
    puts "#{message.yellow}"
  else
    begin
      puts "#{message.yellow} => #{JSON.pretty_generate(data).cyan}"
    rescue
      puts "#{message.yellow} => #{data.inspect.cyan}"
    end
  end
  puts
end

def self.mask(hash, *keys)
  out = {}
  keys.each do |key|
    out[key] = hash[key]
  end
  out[:etc] = "..."
  out
end


include BitVault::Encodings
include BitVault::Crypto

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

email = "matthew-#{Time.now.to_i}@bitvault.io"

user = users.create(
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

client = BV.spawn

# Supply the client with the user password, required to manage the user
# and its applications.  The context class used here determines which
# credential to use based on the authorization scheme.

client.context.set_basic(email, "incredibly_secure")

# Retrieve the user resource

#user = client.resources.user(user.url).get

user = client.resources.login(:email => email).get


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

# Supply the client with the authentication credential
client.context.set_token(application.api_token)

# List applications
list = user.applications.list
log "List the user applications", (list.map do |app|
  mask(app, :name, :api_token, :callback_url)
end)


## Reset or delete the application
#

reset = application.reset

log "Reset an application's api token", {
  :previous_token => application.api_token,
  :new_token => reset.api_token
}

client.context.api_token = reset.api_token


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
  :backup_public_seed => new_wallet.trees[:backup].to_serialized_address,
  :primary_public_seed => new_wallet.trees[:primary].to_serialized_address,
  :primary_private_seed => encrypted_seed
)


log "Create a co-signing wallet for an application", mask(
  wallet,
  :name, :network,
  :backup_public_seed, :primary_public_seed, :cosigner_public_seed
)



## Use the server's response data to construct a MultiWallet
#
# This models what an application would do in any subsequent interactions.
# The MultiWallet will be used later in this script to verify and sign a
# transaction.

primary_seed = PassphraseBox.decrypt(passphrase, wallet.primary_private_seed)
client_wallet = MultiWallet.new(
  :private => {
    :primary => primary_seed
  },
  :public => {
    :cosigner => wallet.cosigner_public_seed,
    :backup => wallet.backup_public_seed
  }
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

incoming_address = account.addresses.create

log "Generate a Bitcoin address to fund the account", mask(
  incoming_address, :path, :string
)


## Request a payment of bitcoins from this account to someone else's address.

payee = Bitcoin::Key.new
payee.generate
payee_address = payee.addr

# Until funded the account can't be used to generate payments or transfers to
# other accounts in the wallet.

log "Fund the address via a Bitcoin transaction, so that you can make payments or transfers"


