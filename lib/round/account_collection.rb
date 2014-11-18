class Round::AccountCollection < Round::Collection

  def initialize(options = {})
    raise ArgumentError, 'AccountCollection must be associated with a wallet' unless options[:wallet]
    @wallet = options[:wallet]
    super(options) {|account| account.wallet = @wallet}
  end

  def content_type
    Round::Account
  end

  def create(name)
    resource = @resource.create(name: name)
    account = Round::Account.new(resource: resource, wallet: @wallet)
    self.add(account)
    account
  end

end