class BitVault::AccountCollection < BitVault::Collection

  def collection_type
    BitVault::Account
  end

  def create(options = {})
    resource = @resource.create(options)
    account = BitVault::Account.new(resource: resource)
    @collection << account
    account
  end

end