class BitVault::Account < BitVault::Base
  def_delegators :@resource, :name, :path, :balance, :pending_balance

  attr_accessor :wallet

  def initialize(options = {})
    raise ArgumentError, 'Account must be associated with a wallet' unless options[:wallet]
    super(options)
    @wallet = options[:wallet]
  end

  def pay(payees, options = {})
    raise ArgumentError, 'Payees must be specified' unless payees
    raise 'You must unlock the wallet before attempting a transaction' unless @wallet.multiwallet

    payment = self.payments.unsigned(payees)
    payment.sign(@wallet.multiwallet)

    BitVault::Payment.new(resource: payment)
  end

  def addresses
    @addresses ||= BitVault::AddressCollection.new(resource: @resource.addresses)
    @addresses
  end

  def transactions
    BitVault::TransactionCollection.new(resource: @resource.transactions)
  end

  def payments
    @payments ||= BitVault::PaymentGenerator.new(resource: @resource.payments)
    @payments
  end

end 