module Round
  class Account < Round::Base
    include Round::Subscriptions

    attr_accessor :wallet

    def initialize(options = {})
      raise ArgumentError, 'Account must be associated with a wallet' unless options[:wallet]
      super(options)
      @wallet = options[:wallet]
    end

    def pay(payees, confirmations = 6)
      raise ArgumentError, 'Payees must be specified' unless payees
      raise 'You must unlock the wallet before attempting a transaction' unless @wallet.multiwallet

      payment = self.unsigned_payment(payees, confirmations)
      payment.sign(@wallet.multiwallet)

      payment
    end

    def unsigned_payment(payees, confirmations = 6)
      raise 'Must have list of payees' unless payees

      payment_resource = @resource.payments.create(
        { confirmations: confirmations }.merge(self.outputs_from_payees(payees))
      )

      Round::Transaction.new(resource: payment_resource)
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

  class AccountCollection < Round::Collection

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

    def refresh
      super(wallet: @wallet)
    end

  end
end
