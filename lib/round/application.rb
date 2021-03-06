module Round
  API_TOKEN = 'api_token'
  TOTP_SECRET = 'totp_secret'
  SUBSCRIPTION_TOKEN = 'subscription_token'

  class Application < Round::Base
    association :users, 'Round::UserCollection'

    def authorize_instance(name)
      @resource.authorize_instance(name: name)
    end

    def wallets(options = {})
      options.merge!(
        resource: @resource.wallets,
        client: @client,
        application: self)
      Round::WalletCollection.new(options)
    end

    def wallet(name)
      Round::Wallet.new(
        resource: @resource.wallet_query(name: name).get,
        client: @client,
        application: self
      )
    end

    def user_from_key(key)
      users.detect { |u| u.key == key }
    end

    def account_from_key(user_key, account_key)
      user_from_key(user_key).accounts.detect { |a| a.key == account_key }
    end

    def self.hash_identifier
      'name'
    end

    def totp=(totp_secret)
      @totp = ROTP::TOTP.new(totp_secret)
    end

    def get_mfa
      @totp.now
    end

    def with_mfa!(token)
      context.mfa_token = token
      self
    end

    def reset(*resets)
      @resource.reset(resets)
      self
    end
  end

  class ApplicationCollection < Round::Collection

    def content_type
      Round::Application
    end

    def create(name, callback_url = nil)
      params = { name: name }
      params.merge!(callback_url: callback_url) if callback_url
      app_resource = @resource.create(params)
      app = Round::Application.new(
        resource: app_resource,
        client: @client
      )
      add(app)
      app
    end

  end
end
