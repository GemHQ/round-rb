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

# List and retrieve applications

log "Application list", user.applications.list

# Client would select from multiple applications based on data in his database

application = user.applications.list[0]
# FIXME: Do we need to do this? It currently makes no difference
#application = application.get

log "Retrieved application", application


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
