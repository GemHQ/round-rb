# BitVault Ruby Client


Required system dependencies are sqlite3 and libsodium.  On OS X, homebrew suffices.

Developed against Ruby 2.1.x.  Rubygem dependencies can be installed by running `rake gem:deps`.


To run the client usage script against an instance of the bitvault API

    ruby test/scripts/client_usage.rb <api_url>

