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
      query[:status] = query[:status].join(',') if query[:status]
      Round::TransactionCollection.new(
        resource: @resource.transactions(query),
        client: @client
      )
    end

    def pay(payees, confirmations, redirect_uri = nil, mfa_token: nil)
      raise ArgumentError, 'Payees must be specified' unless payees
      raise 'You must unlock the wallet before attempting a transaction' unless @wallet.multiwallet

      payment = self.transactions.create(payees, confirmations, redirect_uri: redirect_uri)
      signed = payment.sign(@wallet.multiwallet, network: network.to_sym)
      if mfa_token && wallet.application
        @client.context.mfa_token = mfa_token
        signed.approve
      end
      signed
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

    def create(name:, network:)
      unless [:testnet, :bitcoin].include?(network)
        raise ArgumentError, 'Network must be :testnet or :bitcoin.'
      end
      resource = @resource.create(name: name, network: network)
      account = Round::Account.new(resource: resource, wallet: @wallet, client: @client)
      add(account)
      account
    end

    def refresh
      super(wallet: @wallet)
    end

  end
end
