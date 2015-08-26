module Round
  class Account < Round::Base
    association :addresses, 'Round::AddressCollection'
    association :subscriptions, 'Round::SubscriptionCollection'

    attr_reader :wallet

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
      raise 'You must unlock the wallet before attempting a transaction' unless @wallet.multiwallet

      payment = self.transactions.create(payees, confirmations)
      signed = payment.sign(@wallet.multiwallet, 
                            redirect_uri: redirect_uri, 
                            network: network.to_sym)
      if wallet.application
        mfa_token = mfa_token || @wallet.application.get_mfa
        signed.approve(mfa_token)
        signed.refresh
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
      unless [:bitcoin_testnet, :bitcoin, :litecoin, :dogecoin].include?(network)
        raise ArgumentError, 'Network must be :bitcoin_testnet, :dogecoin, :litecoin, :bitcoin.'
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
