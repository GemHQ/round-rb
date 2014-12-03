module Round
  class Application < Round::Base

    def users
      @users ||= Round::UserCollection.new(resource: @resource.users)
    end

    def authorize_instance(name)
      @resource.authorize_instance(name: name)
    end

  end
end