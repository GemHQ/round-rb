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
user_url = "http://localhost:8999/users/Kw8aTuNfh6ZXKpq1CpmRMf"
client.context.password = "incredibly_secure"

# Retrieve the user resource

user = client.resources.user(user_url).get


## Update some attributes for the user

user = user.update(:first_name => "Matt")
log "User updated", user
