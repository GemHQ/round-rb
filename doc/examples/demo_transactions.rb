
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
app_url, api_token, wallet_data, account_data =
  data.values_at :app_url, :api_token, :wallet, :account

## Create a "sub-client" with its own context

client = BitVault::Patchboard.authed_client(app_url: app_url, api_token: api_token)

# Fetch the wallet and unlock it
wallet = client.wallet(url: wallet_data[:url])
wallet.unlock(wallet_data[:passphrase])

account = wallet.accounts[account_data[:name]]
log "Fetched account", mask(account, :name, :path, :balance, :pending_balance)

transactions = account.transactions

log "Account transactions", (transactions.map do |transaction|
  mask(transaction, :type, :data)
end)


