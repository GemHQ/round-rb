class Round::Application < Round::Base

  def users
    @users ||= Round::UserCollection.new(resource: @resource.users)
  end

end
