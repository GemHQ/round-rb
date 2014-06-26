
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
log "Fetched account", mask(account, :url, :name)


## Request a payment of bitcoins from this account back to the faucet address.
# faucet donation address mwwhVPiopW6HhhDtcSv3MUFLTB5ehhkgZg

payees = [
  {
    address: "mwwhVPiopW6HhhDtcSv3MUFLTB5ehhkgZg",
    amount: 2_000_000
  }
]

payment = account.pay(payees)

log "Signed payment", mask(payment, :status, :hash)


# The client will then be able to check the confirmation status of the signed
# payment.  Exact API to be determined.  To mitigate the need for polling, the
# service will post transaction statuses to the application's callback_url,
# if supplied.

log "Check transaction confirmations at:\nhttp://tbtc.blockr.io/tx/info/#{payment.hash}"




