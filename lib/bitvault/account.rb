class BitVault::Account < BitVault::Base
  attr_accessor :wallet

  def initialize(options = {})
    raise ArgumentError, 'Account must be associated with a wallet' unless options[:wallet]
    super(options)
    @wallet = options[:wallet]
  end
end 