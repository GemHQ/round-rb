class Round::AccountCollection < Round::Collection

  def initialize(options = {})
    raise ArgumentError, 'AccountCollection must be associated with a wallet' unless options[:wallet]
    @wallet = options[:wallet]
    super(options)
  end

  def content_type
    Round::Account
  end

  def create(options = {})
    resource = @resource.create(options)
    account = Round::Account.new(resource: resource, wallet: @wallet)
    self.add(account)
    account
  end

end