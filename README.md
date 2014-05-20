# BitVault Ruby Client


## Installation

Required system dependencies:

* libsodium

Developed against Ruby 2.1.x.  To bootstrap:

    $ gem install starter

Rubygem dependencies can then be installed by running `rake gem:deps`.

To run the demo script against the alpha server, check out the "development"
branch:

    git checkout development

Then run this:

    ruby doc/examples/demo_usage.rb http://bitvault.pandastrike.com

To run the demo script against an arbitrary instance of the BitVault API:

    ruby doc/examples/demo_usage.rb <url>






