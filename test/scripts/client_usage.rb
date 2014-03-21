require_relative "setup"

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn

user = client.resources.users.create :email => "matthew-#{rand(10000)}@mail.com"
pp user
