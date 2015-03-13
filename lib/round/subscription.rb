module Round
  class Subscription < Round::Base
    module SubscriptionType
      ADDRESS = 'address'
    end
  end

  class SubscriptionCollection < Round::Collection
    def content_type
      Round::Subscription
    end

    def create(callback_url, type = Subscription::SubscriptionType::ADDRESS)
      resource = @resource.create(callback_url: callback_url, subscribed_to: type)
      Subscription.new(resource: resource, client: @client)
    end
  end

  module Subscriptions
    def subscriptions
      SubscriptionCollection.new(resource: @resource.subscriptions, client: @client)
    end
  end
end