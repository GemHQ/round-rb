class BitVault::Account < BitVault::Base
  attr_accessor :wallet

  def initialize(options = {})
    raise ArgumentError, 'Account must be associated with a wallet' unless options[:wallet]
    super(options)
    @wallet = options[:wallet]
  end

  def pay(options = {})
    raise ArgumentError, 'Payees must be specified' unless options[:payees]
    raise 'You must unlock the wallet before attempting a transaction' unless @wallet.multiwallet

    unsigned_payment = @resource.payments.create self.outputs_from_payees(options[:payees])
    transaction = CoinOp::Bit::Transaction.data(unsigned_payment)
    signed_payment = self.sign_payment(unsigned_payment, transaction)

    BitVault::Transaction.new(resource: signed_payment)
  end

  def outputs_from_payees(payees)
    raise ArgumentError, 'Payees must be an array' unless payees.is_a?(Array)
    outputs = payees.map do |payee|
      raise 'Bad output, no amount' unless payee[:amount]
      raise 'Bad output, no address' unless payee[:address]
      {
        amount: payee[:amount],
        payee: { address: payee[:address] }
      }
    end
    { outputs: outputs }
  end

  def sign_payment(unsigned_payment, transaction)
    raise ArgumentError, 'unsigned_payment is required' unless unsigned_payment
    raise ArgumentError, 'transaction is required' unless transaction
    raise "bad change address" unless @wallet.multiwallet.valid_output?(transaction.outputs.last)
    unsigned_payment.sign(
      transaction_hash: transaction.base58_hash,
      inputs: @wallet.multiwallet.signatures(transaction)
    )
  end

  def addresses
    @addresses ||= BitVault::AddressCollection.new(resource: @resource.addresses)
    @addresses
  end

end 