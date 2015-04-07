require "patchboard"
require "base64"
require "date"

module Round

  MAINNET_URL = 'https://api.gem.co'
  SANDBOX_URL = 'https://api-sandbox.gem.co'

  NETWORKS = {
    testnet: :bitcoin_testnet,
    bitcoin_testnet: :bitcoin_testnet,
    testnet3: :bitcoin_testnet,
    bitcoin: :bitcoin,
    mainnet: :bitcoin,
  }

  def self.client(network = :bitcoin_testnet, url = nil)
    network = NETWORKS.fetch(network, :bitcoin_testnet)
    url ||= network == :bitcoin_testnet ? SANDBOX_URL : MAINNET_URL

    @patchboard ||= ::Patchboard.discover(url) { Client::Context.new }
    Client.new(@patchboard.spawn, network)
  end

  class Client
    include Round::Helpers

    attr_reader :network

    def initialize(patchboard_client, network)
      @patchboard_client = patchboard_client
      @network = network
    end

    def authenticate_application_instance(app_url: nil, api_token: nil, instance_id: nil)
      raise ArgumentError.new 'app_url is a required argument' unless app_url
      raise ArgumentError.new 'api_token is a required argument' unless api_token

      @patchboard_client
        .context
        .authorize(Context::Scheme::APPLICATION, 
          api_token: api_token, instance_id: instance_id)
      authenticate_application(api_token: api_token)

      self.application(app_url).refresh
    end

    def authenticate_application(api_token: nil)
      @patchboard_client
        .context
        .authorize(Context::Scheme::IDENTIFY, api_token: api_token)
    end

    def authenticate_device(email: nil, api_token: nil, device_id: nil)
      @patchboard_client
        .context
        .authorize(Context::Scheme::DEVICE, 
          api_token: api_token, device_id: device_id)
      @patchboard_client
        .context
        .authorize(Context::Scheme::IDENTIFY, 
          api_token: api_token)
      self.user(email).refresh
    end

    def resources
      @patchboard_client.resources
    end

    def users
      UserCollection.new(resource: resources.users, client: self)
    end

    def application(app_url)
      raise ArgumentError, 'app_url is a required argument' unless app_url
      Application.new(resource: resources.application(app_url), client: self)
    end

    def user(email)
      raise ArgumentError, 'email is a required argument' unless email
      User.new(resource: resources.user_query(email: email), client: self)
    end

    class Context
      module Scheme
        DEVICE = 'Gem-Device'
        APPLICATION = 'Gem-Application'
        IDENTIFY = 'Gem-Identify'
      end

      SCHEMES = [Scheme::DEVICE, Scheme::APPLICATION, Scheme::IDENTIFY]

      attr_accessor :schemes

      def initialize
        @schemes = {}
      end

      # Is there a list of accepted params somewhere?
      def authorize(scheme, params)
        raise ArgumentError, 'Params cannot be empty.' if params.empty?
        raise ArgumentError, 'Unknown auth scheme' unless SCHEMES.include?(scheme)
        @schemes[scheme] = params
      end

      def compile_params(params)
        params.map do |key, value|
          %Q(#{key}="#{value}")
        end.join(', ')
      end

      def authorizer(schemes: [], action: 'NULL ACTION', **kwargs)
        schemes.each do |scheme|
          if (params = @schemes[scheme])
            credential = compile_params(params)
            return [scheme, credential]
          end
        end
        raise "Action: #{action}.  No authorization available for '#{schemes}'"
      end

      def inspect
        # Hide the secret token when printed
        id = "%x" % (self.object_id << 1)
        %Q(#<#{self.class}:0x#{id})
      end
    end

    UnknownKeyError = Class.new(StandardError)
    OTPConflictError = Class.new(StandardError)

    class OTPAuthFailureError < StandardError
      attr_reader :key

      def initialize(key)
        super
        @key = key
      end
    end


  end

end
