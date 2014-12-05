module Round
  class User < Round::Base
    include Round::Helpers

    def wallets
      @wallets ||= Round::WalletCollection.new(resource: @resource.wallets)
    end

    def default_wallet
      Wallet.new(resource: @resource.default_wallet, client: @client)
    end

    def begin_device_authorization(name, device_id, api_token)
      @client.authenticate_otp(api_token)
      @resource = @resource.authorize_device(name: name, device_id: device_id)
    rescue Patchboard::Action::ResponseError => e
      raise e unless e.status == 401
      authorization_header = e.headers['Www-Authenticate']
      key = extract_params(authorization_header)[:key]
      if key
        key
      else
        raise Round::Client::OTPConflictError.new("This user has too many pending authorizations")
      end
    end

    def complete_device_authorization(name, device_id, api_token, key = nil, secret = nil)
      @client.authenticate_otp(api_token, key, secret)
      @resource = @resource.authorize_device(name: name, device_id: device_id)
      @client.authenticate_device(api_token, self.user_token, device_id, self.email)
      self
    rescue Patchboard::Action::ResponseError => e
      raise e unless e.status == 401
      authorization_header = e.headers['Www-Authenticate']
      new_key = extract_params(authorization_header)[:key]
      if new_key
        new_key
      else
        raise Round::Client::UnknownKeyError.new("The OTP key you provided doesn't exist")
      end
    end

  end
end