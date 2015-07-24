module Round
  class User < Round::Base
    association :default_wallet, 'Round::Wallet'

    def self.hash_identifier
      'email'
    end

    def initialize(resource:, client:, **kwargs)
      super
      @resource.attributes.merge! kwargs
    end

    def devices
      resource = @client.resources.devices_query(
        email: self.email
      )
      Round::DeviceCollection.new(
        resource: resource,
        client: @client
      )
    end

    def wallet
      default_wallet
    end
  end

  class UserCollection < Round::Collection

    def content_type
      Round::User
    end

   def create(first_name:, last_name:, email:, passphrase:,
              device_name:, redirect_uri: nil)
      multiwallet = CoinOp::Bit::MultiWallet.generate([:primary])
      primary_seed = CoinOp::Encodings.hex(multiwallet.trees[:primary].seed)
      encrypted_seed = CoinOp::Crypto::PassphraseBox.encrypt(passphrase, primary_seed)
      wallet = {
        name: 'default',
        primary_public_seed: multiwallet.trees[:primary].to_bip32,
        primary_private_seed: encrypted_seed
      }
      params = {
        email: email,
        first_name: first_name,
        last_name: last_name,
        default_wallet: wallet,
        device_name: device_name,
      }
      params[:redirect_uri] = redirect_uri if redirect_uri
      user_resource = resource.create(params)
      user = Round::User.new(resource: user_resource, client: @client)
      user.metadata.device_token
    end

  end
end
