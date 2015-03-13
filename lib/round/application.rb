module Round
  class Application < Round::Base

    def users
      @users ||= Round::UserCollection.new(resource: @resource.users, client: @client)
    end

    def authorize_instance(name)
      @resource.authorize_instance(name: name)
    end

  end

  class ApplicationCollection < Round::Collection

    def create(name, callback_url = nil)
      params = { name: name }
      params.merge!(callback_url: callback_url) if callback_url
      app_resource = @resource.create(params)
      app = Round::Application.new(resource: app_resource)
      self.add(app)
      app
    end

    def content_type
      Round::Application
    end

  end
end