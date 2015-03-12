# Gem Ruby Client

For detailed usage please visit the [documentation page](https://guide.gem.co)

## Installation

### Install gem dependencies:

    $ bundle install

### Build and install the gem:

    $ gem build round.gemspec
    $ gem install round-0.6.0.gem

## Configuration

You'll need to add `round` to your Gemfile:

    gem 'round'

In Rails you may want to create a single instance of a client to be reused many times and store your credentials in a YAML file:

__config/round.yml__

```yaml
production:
    app_url: <PRODUCTION_APP_URL>
    api_token: <PRODUCTION_API_TOKEN>
    instance_id: <PRODUCTION_INSTANCE_ID>

development:
    app_url: <DEVELOPMENT_APP_URL>
    api_token: <DEVELOPMENT_API_TOKEN>
    instance_id: <DEVELOPMENT_INSTANCE_ID>
```

__config/initializers/round.rb__
```ruby
config = YAML::load(File.read("#{Rails.root}/config/round.yml"))[Rails.env]

ROUND_CLIENT = Round.client
ROUND_CLIENT.authenticate_application(config[:app_url], config[:api_token], config[:instance_id])
```

This is just a suggestion for a simple Rails setup, there are many other ways to do this.

## Authentication

You must authenticate to interact with the API. Depending on what you are trying to do there are different authentication schemes available.

### Developer

Authenticating as a developer will allow you create and manage your applications. Authenticating in this way requires the developer's email, as well as their private key. The method will return a `Round::Developer` object.
```ruby
developer = ROUND_CLIENT.authenticate_developer(<DEVELOPER_EMAIL>, <DEVELOPER_PRIVATE_KEY>)
```

### Application

Authenticating as an application will give you read-only access to your users and their wallets. This requires the `app_url`, the `api_token`, and an `instance_id`. The method will return a `Round::Application` object.
```ruby
application = ROUND_CLIENT.authenticate_application(<APP_URL>, <API_TOKEN>, <INSTANCE_ID>)
```
Your `instance_id` is provided to you via email when you authorize an application instance using Developer auth:
```ruby
developer = ROUND_CLIENT.authenticate_developer(<DEVELOPER_EMAIL>, <DEVELOPER_PRIVATE_KEY>)
application = developer.applications.first
application.authorize_instance
```

### Device

Authenticating as a device allows you to perform all actions on a wallet permitted by a user. Requires an `email`, an `api_token`, a `user_token`, and a `device_id`. The method will return a `Round::User` object.
```ruby
user = ROUND_CLIENT.authenticate_device(<EMAIL>, <API_TOKEN>, <USER_TOKEN>, <DEVICE_ID>)
```
The `user_token` is obtained by a user authorizing your application to operate on their wallet in the `User#authorize_device` call:
```ruby
user = client.user(<EMAIL>)
key = ROUND_CLIENT.begin_device_authorization(<DEVICE_NAME>, <DEVICE_ID>, <API_TOKEN>)
```

This will trigger an out of band email to the user that will include a one time pass that will allow the authorization to complete by running the same call with that value:
```ruby
ROUND_CLIENT.complete_device_authorization(<DEVICE_NAME>, <DEVICE_ID>, <API_TOKEN>, key, <OTP_FROM_EMAIL>)
```

## Basic Usage

### Wallets

Once you've got a User authenticated with a device you can start to do fun stuff like create wallets:

```ruby
wallet = user.wallets.create(name: <WALLET_NAME>, passphrase: <WALLET_PASSPHRASE>)
```

__IMPORTANT__: Creating a wallet this way will automatically generate your backup key tree. You can get it by accessing `BitVault::Wallet#multiwallet`. This will return the `CoinOp::Bit::MultiWallet` object containing both private seeds. __Make sure you save it somewhere__.

### Accounts

Once you have a wallet you're going to want to send and receive funds from it, right? You do this by creating accounts within the wallet:
```ruby
account = wallet.accounts.create(<ACCOUNT_NAME>)
```

To receive payments, you'll have to generate a new address:
```ruby
address = account.addresses.create
```

Sending payments is easy too:
```ruby
account.pay([{address: <PAYEE_ADDRESS>, amount: <AMOUNT_TO_PAY>}])
```

You can add as many payees as you need.
Don't forget to unlock the wallet before trying to pay someone:
```ruby
account.wallet.unlock(<PASSPHRASE>)
```
