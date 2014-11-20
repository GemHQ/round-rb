class Round::User < Round::Base
  include Round::Helpers

  def wallets
    @wallets ||= Round::WalletCollection.new(resource: @resource.wallets)
  end

  def default_wallet
    Wallet.new(resource: @resource.default_wallet, client: @client)
  end

  def begin_device_authorization(name, device_id, api_token)
    @client.authenticate_otp(api_token, key, secret)
    @resource = @resource.authorize_device(name: name, device_id: device_id)
  rescue Patchboard::Action::ResponseError => e
    authorization_header = e.headers['Www-Authenticate']
    extract_params(authorization_header)[:key]
  end

  def complete_device_authorization(name, device_id, api_token, key = nil, secret = nil)
    @client.authenticate_otp(api_token, key, secret)
    @resource = @resource.authorize_device(name: name, device_id: device_id)
    @client.authenticate_device(self.email, api_token, self.user_token, device_id)
    self
  end

end