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
  :password => "incredibly_secure"
)
log "User", user

# The create action returned a User Resource which has:
#
# * action methods (get, update, reset)
# * attributes (email, first_name, etc.)
# * associated resources (applications)

# The client will use this URL to retrieve this user in later sessions
# TODO: maybe this needs more documentation?

log "User URL", user.url
