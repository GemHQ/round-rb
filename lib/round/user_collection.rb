class Round::UserCollection < Round::Base

  def create(options = {})
    raise ArgumentError, 'Email and password is required' unless options[:email] and options[:password]
    user_resource = @resource.create(options)
    Round::User.new(resource: user_resource)
  end

end
