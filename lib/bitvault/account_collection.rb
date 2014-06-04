class BitVault::AccountCollection < BitVault::Collection

  def initialize(options = {})
    raise ArgumentError, 'AccountCollection must be associated with a wallet' unless options[:wallet]
    @wallet = options[:wallet]
    super(options)
  end

  def content_type
    BitVault::Account
  end

  def create(options = {})
    resource = @resource.create(options)
    account = BitVault::Account.new(resource: resource, wallet: self)
    @collection << account
    account
  end

end