# BitVault Ruby Client


## Installation

Required system dependencies:

* libsodium

Developed against Ruby 2.1.x.  To bootstrap:

    $ gem install starter

Rubygem dependencies can then be installed by running `rake gem:deps`.

To run the usage script against the demo server, check out the "development"
branch:

    git checkout development

Then run this:

    ruby test/scripts/client_usage.rb http://bitvault-api.pandastrike.com

To run the usage script against an arbitrary instance of the BitVault API:

    ruby test/scripts/client_usage.rb <url>

The (very verbose) output shows the JSON for the results of API actions.





