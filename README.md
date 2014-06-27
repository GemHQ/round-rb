# BitVault Ruby Client

## Installation

### Install [libsodium](https://github.com/jedisct1/libsodium) 

On OS X using [Brew](http://brew.sh/):

    $ brew install libsodium

Follow the instructions on the [libsodium](https://github.com/jedisct1/libsodium) Github page for installation instructions on *nix systems.

### Install gem dependencies:

    $ bundle install

### Build and install the gem:

    $ gem build bitvault.gemspec
    $ gem install bitvault

## Configuration

You'll need to add bitvault-rb to your Gemfile:

    gem 'bitvault'

In Rails you may want to create a single instance of a client to be reused many times and store your credentials in a YAML file:

__config/bitvault.yml__

    production:
        app_url: <PRODUCTION_APP_URL>
        api_token: <PRODUCTION_API_TOKEN>
    
    development: 
        app_url: <DEVELOPMENT_APP_URL>
        api_token: <DEVELOPMENT_API_TOKEN>

__config/initializers/bitvault.rb__

    config = YAML::load(File.read("#{Rails.root}/config/bitvault.yml"))[Rails.env]

    BITVAULT_CLIENT = BitVault::Patchboard.authed_client(app_url: config['app_url'], api_token: ['api_token'])
    
This is just a suggestion for a simple Rails setup, there are many other ways to do this.

## Awesome things you can do

Now that you have this thing installed, let's do some cool stuff with it.

### Spawning a client

If your use case requires you to have several clients authed with different credentials you can spawn as many as you'd like.

You can do this 2 ways:
    
    client = BitVault::Patchboard.authed_client(email: <EMAIL>, password: <PASSWORD>)
    
or

    client = BitVault::Patchboard.authed_client(app_url: <APP_URL>, api_token: <API_TOKEN>)

You can do basic user management with a client authed using user credentials, but in order to do any operations on wallets or accounts you'll need to do the second option to auth a client using application credentials.

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
    
