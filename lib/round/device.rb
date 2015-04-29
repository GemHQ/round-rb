module Round
  class Device < Base

  end

  class DeviceCollection < Base

    def create(name, redirect_uri: nil)
      params = { name: name }
      params[:redirect_uri] = redirect_uri if redirect_uri
      auth_request_resource = @resource.create(params)
      device_token = auth_request_resource.metadata.device_token
      mfa_uri = auth_request_resource.mfa_uri
      [device_token, mfa_uri]
    end
  end
end
