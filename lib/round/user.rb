class Round::User < Round::Base
  include Round::Helpers

  attr_reader :wallet

  def initialize(options = {})
    super
    @wallet = options[:wallet]
  end

  def wallets
    @wallets ||= Round::WalletCollection.new(resource: @resource.wallets)
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