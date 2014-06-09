# BitVault Ruby Client


## Installation

Required system dependencies:

* libsodium

Developed against Ruby 2.1.x.  To bootstrap:

    $ gem install starter

Rubygem dependencies can then be installed by running `rake gem:deps`.

There are two demo scripts, one to set up an account and an address for funding
the account, another to issue payments from the account.

To run these scripts against the alpha server, check out the "development"
branch:

    git checkout development

Then do this:

    ruby doc/examples/demo_account.rb
    # follow instructions for funding from a testnet faucet
    ruby doc/examples/demo_payment.rb

To run the demo script against an arbitrary instance of the BitVault API:

    ruby doc/examples/demo_account.rb <url>
    ruby doc/examples/demo_payment.rb <url>

## Awesome things you can do

Now that you have this thing installed, let's do some cool stuff with it.

### Spawning a client

For most things, you will want to spawn an authenticated client with your credentials.

You can do this 2 ways:
    
    client = BitVault::Patchboard.authed_client(email: <EMAIL>, password: <PASSWORD>)
    
or

    client = BitVault::Patchboard.authed_client(app_url: <APP_URL>, api_token: <API_TOKEN>)
    
### Wallets

Once you've got a client with an Application context you can start to do fun stuff like create wallets:

    wallet = client.application.wallets.create(name: <WALLET_NAME>, passphrase: <WALLET_PASSPHRASE>)
    
__IMPORTANT__: Creating a wallet this way will automatically generate your backup key tree. You can get it by accessing `BitVault::Wallet#multiwallet`. This will return the `CoinOp::Bit::MultiWallet` object containing both private seeds. __Make sure you save it somewhere__.

Alternatively you can generate your own `Coin::Bit::MultiWallet` and pass it as an option to the wallet create call:

    multiwallet = Coin::Bit::Multiwallet.generate [:primary, :backup]
    wallet = client.application.wallets.create(name: <WALLET_NAME>, passphrase: <WALLET_PASSPHRASE>, multiwallet: multiwallet)
    
You can also access existing wallets by name:

    wallet = client.application.wallets['my funds']
    
### Accounts

Once you have a wallet you're going to want to send and receive funds from it, right? You do this by creating accounts within the wallet:

    account = wallet.accounts.create(name: <ACCOUNT_NAME>)
    
Existing accounts can also be accessed by name, just like the wallets:

    account = wallet.accounts['office supplies']
    
To receive payments, you'll have to generate a new address:

    address = account.addresses.create

Sending payments is easy too:

    account.pay([{address: <PAYEE_ADDRESS>, amount: <AMOUNT_TO_PAY>}])

You can add as many payees as you need.
Don't forget to unlock the wallet before trying to pay someone:

    account.wallet.unlock(<PASSPHRASE>)
    
### Transfers

Need to move money between two accounts? Try this:

    source_account = wallet.accounts['office supplies']
    destination_account = wallet.accounts['furniture']
    wallet.transfer(source: source_account, desination: destination_account, amount: <TRANSFER_AMOUNT>)
    
Again, don't forget to unlock the wallet before attempting this:

    wallet.unlock(<PASSPHRASE>)
    
