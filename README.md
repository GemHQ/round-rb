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






