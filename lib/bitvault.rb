require 'coin-op'

# Establish the namespace.
module BitVault

end

require_relative "bitvault/client"
require_relative "bitvault/base"
require_relative "bitvault/collection"
require_relative "bitvault/user"
require_relative "bitvault/user_collection"
require_relative "bitvault/application"
require_relative "bitvault/application_collection"
require_relative "bitvault/wallet"
require_relative "bitvault/wallet_collection"
require_relative "bitvault/account"
require_relative "bitvault/account_collection"
require_relative "bitvault/address"
require_relative "bitvault/address_collection"
require_relative "bitvault/transaction"
require_relative "bitvault/transaction_collection"
require_relative "bitvault/payment"
require_relative "bitvault/payment_generator"
require_relative "bitvault/blockchain/mockchain"
require_relative "bitvault/blockchain/blockr"

