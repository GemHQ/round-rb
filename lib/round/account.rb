module Round
  class Account < Round::Base
    association :addresses, 'Round::AddressCollection'
    association :subscriptions, 'Round::SubscriptionCollection'

    attr_accessor :wallet

    def initialize(options = {})
      raise ArgumentError, 'Account must be associated with a wallet' unless options[:wallet]
      super(options)
      @wallet = options[:wallet]
    end

    def transactions(**query)
      Round::TransactionCollection.new(
        resource: @resource.transactions(query),
        client: @client
      )
    end

    def pay(payees, confirmations, redirect_uri = nil)
      raise ArgumentError, 'Payees must be specified' unless payees
      raise 'You must unlock the wallet before attempting a transaction' unless @wallet.multiwallet

      payment = self.transactions.create(payees, confirmations, redirect_uri: redirect_uri)
      payment.sign(@wallet.multiwallet)
    end

    def self.hash_identifier
      "name"
    end

  end

  class AccountCollection < Round::Collection

    def initialize(options = {})
      raise ArgumentError, 'AccountCollection must be associated with a wallet' unless options[:wallet]
      @wallet = options[:wallet]
      super(options) { |account| account.wallet = @wallet }
    end

    def content_type
      Round::Account
    end

    def create(name)
      resource = @resource.create(name: name)
      account = Round::Account.new(resource: resource, wallet: @wallet, client: @client)
      add(account)
      account
    end

    def refresh
      super(wallet: @wallet)
    end

  end
end
