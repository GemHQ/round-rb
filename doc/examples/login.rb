require_relative "setup"

url = "http://bitvault.pandastrike.com"

BV = BitVault::Client.discover(url) { BitVault::Client::Context.new }
client = BV.spawn

email = "julian@bitvault.io"

client.context.set_basic(email, "i can authenticating")

begin
  client.resources.login(:email => email).get
rescue => error
  pp error
end