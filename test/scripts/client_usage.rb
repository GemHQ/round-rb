require_relative "setup"

include BitVault::Bitcoin::Encodings

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn

# Create a user
user = client.resources.users.create :email => "matthew-#{rand(10000)}@mail.com"
pp user

# Tell the client about the authentication token
client.context.api_token = user.api_token

# Generate a wallet with new seeds
wallet = BitVault::Bitcoin::MultiWallet.generate [:hot, :cold]

# Derive a secret key from a passphrase
passphrase = BitVault::Client::Passphrase.new "this is not a secure passphrase"
key, salt = passphrase.key, passphrase.salt

# Encrypt the hot seed with the secret key
nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
hot_seed = wallet.trees[:hot].to_serialized_address(:private)
ciphertext = RbNaCl::SecretBox.new(key).encrypt(nonce, hot_seed)


wallet = user.wallets.create(
  :name => "my favorite wallet",
  :network => "bitcoin_testnet",
  :cold_address => wallet.trees[:cold].to_serialized_address,
  :hot_address => wallet.trees[:hot].to_serialized_address,
  :hot_seed => {
    :passphrase_salt => base58(salt),
    :cipher_nonce => base58(nonce),
    :ciphertext => base58(ciphertext),
  }
)
pp :wallet => wallet.attributes
puts

account = wallet.accounts.create :name => "office supplies"
pp :account => account.attributes

pp :account_list => wallet.accounts.list

address = account.addresses.create

#"M/#{account.i_value}/#{int_or_ext?}/#{i_value}"
# M/22/0/100
pp :address => address.attributes

