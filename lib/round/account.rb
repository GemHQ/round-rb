module Round
  class Account < Round::Base

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

      payment
    end

    def addresses
      @addresses ||= Round::AddressCollection.new(resource: @resource.addresses, client: @client)
    end

    def transactions
      Round::TransactionCollection.new(resource: @resource.transactions, client: @client)
    end

    def payments
      @payments ||= Round::PaymentGenerator.new(resource: @resource.payments, client: @client)
    end

  end 
end