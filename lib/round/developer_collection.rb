class Round::DeveloperCollection < Round::Base

  def create(email, pubkey)
    raise ArgumentError, 'Email and pubkey is required' unless email and pubkey
    user_resource = @resource.create(email: email, pubkey: pubkey)
    Round::Developer.new(resource: user_resource)
  end

end
