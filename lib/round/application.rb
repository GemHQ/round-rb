module Round
  class Application < Round::Base

    def users
      @users ||= Round::UserCollection.new(resource: @resource.users, client: @client)
    end

    def authorize_instance(name)
      @resource.authorize_instance(name: name)
    end

  end
end