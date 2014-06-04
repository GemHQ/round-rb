class BitVault::AddressCollection < BitVault::Collection

  def content_type
    BitVault::Address
  end

  def create
    resource = @resource.create
    address = BitVault::Address.new(resource: resource)
    @collection << address
    address
  end
end