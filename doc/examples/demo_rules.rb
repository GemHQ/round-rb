
require_relative "setup"

require "uri"
host = URI.parse(bitvault_url).hostname

saved_file = "demo-#{host}.yaml"

unless File.exists? saved_file
  puts
  puts <<-MESSAGE
  This script requires output from demo_account.rb, which will be
  found in #{saved_file}.
  Run demo_account.rb first, then fund the address provided using
  a testnet faucet.  Once the transaction has 6 confirmations,
  you should be able to run this script.
  MESSAGE
  exit
end

data = YAML.load_file saved_file
user_data = data[:user]
app_url, api_token, wallet_data, account_data =
  data.values_at :app_url, :api_token, :wallet, :account

## Create a client authenticated as the user
client = BitVault.authenticate :url => ARGV[0], :user => user_data
client.set_application(app_url, api_token)


application = client.application
wallet = client.wallet(:url => wallet_data[:url])
account = wallet.accounts[account_data[:name]]

log "The application starts with no active rules",
  application.rules.to_hash

# The unless clause is here in case the script had crashed,
# as the whitelist would not have been deleted.
unless whitelist = application.rules["gem:whitelist"]
  whitelist = application.rules.add("gem:whitelist")
end

log "Add rules using their names.  Whitelists are empty to begin with.",
  mask(whitelist, :name, :data)

log "Now the whitelist shows up in the application rules",
  application.rules.refresh.to_hash

whitelist = whitelist.set(
  "banana merchant" => {
    :type => :address,
    :value => "mp1vqX3gEH9dTXvFL7d36FtBCQQWSGusnG",
    :memo => "The banana merchant from the corner of 5th and Wilshire."
  },
  wallet.name => {
    :type => "wallet",
    :value => wallet
  },
  account.name => {
    :type => "account",
    :value => account
  }
)

log "Set whitelist entries.  The 'memo' field is optional",
  mask(whitelist, :name, :data)

result = whitelist.delete

log "When you delete a rule, the response contains the deleted content.",
  mask(result, :name, :data)





