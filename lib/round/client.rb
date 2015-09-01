require 'patchboard'
require 'base64'
require 'date'

module Round

  MAINNET_URL = 'https://api.gem.co'

  def self.client(url = MAINNET_URL)
    @patchboard ||= ::Patchboard.discover(url) { Client::Context.new }
    Client.new(@patchboard.spawn)
  end

  class Client
    include Round::Helpers

    def initialize(patchboard_client)
      @patchboard_client = patchboard_client
    end

    def authenticate_application(api_token:, admin_token:)
      @patchboard_client
        .context
        .authorize(Context::Scheme::APPLICATION,
          api_token: api_token, admin_token: admin_token)
      authenticate_identify(api_token: api_token)

      self.application.refresh
    end

    def context
      @patchboard_client.context
    end

    def authenticate_identify(api_token:)
      @patchboard_client
        .context
        .authorize(Context::Scheme::IDENTIFY, api_token: api_token)
    end

    def authenticate_device(email:, api_token:, device_token:)
      @patchboard_client
        .context
        .authorize(Context::Scheme::DEVICE,
          api_token: api_token, device_token: device_token)
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

    def application
      Application.new(resource: resources.app.get, client: self)
    end

    def user(email)
      User.new(resource: resources.user_query(email: email), client: self, email: email)
    end

    class Context
      module Scheme
        DEVICE = 'Gem-Device'
        APPLICATION = 'Gem-Application'
        IDENTIFY = 'Gem-Identify'
      end

      SCHEMES = [Scheme::DEVICE, Scheme::APPLICATION, Scheme::IDENTIFY]

      attr_accessor :schemes, :mfa_token

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
        compiled = params.map do |key, value|
          %Q(#{key}="#{value}")
        end.join(', ')
        compiled << ", mfa_token=#{@mfa_token}" if @mfa_token
        compiled
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
