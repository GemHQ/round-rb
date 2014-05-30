class BitVault::Account < BitVault::Base
  attr_accessor :wallet

  def initialize(options = {})
    raise ArgumentError, 'Account must be associated with a wallet' unless options[:wallet]
    super(options)
    @wallet = options[:wallet]
  end

  def pay(options = {})
    raise ArgumentError, 'Payees must be specified' unless options[:payees]
    raise ArgumentError, 'Payees must be an array' unless options[:payees].is_a?(Array)
  end

end 