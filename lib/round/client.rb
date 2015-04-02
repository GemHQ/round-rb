require "patchboard"
require "base64"
require "date"

module Round

  MAINNET_URL = "https://api.gem.co"
  SANDBOX_URL = "https://api-sandbox.gem.co"

  NETWORKS = {
    testnet: :bitcoin_testnet,
    bitcoin_testnet: :bitcoin_testnet,
    testnet3: :bitcoin_testnet,
    bitcoin: :bitcoin,
    mainnet: :bitcoin,
  }

  def self.client(network = :bitcoin_testnet, url = nil)
    network = NETWORKS[network] || :bitcoin_testnet
    url ||= network.eql?(:bitcoin_testnet) ? SANDBOX_URL : MAINNET_URL

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

    def authenticate_application(app_url: nil, api_token: nil, instance_id: nil)
      raise ArgumentError.new 'app_url is a required argument' unless app_url
      raise ArgumentError.new 'api_token is a required argument' unless api_token
      raise ArgumentError.new 'instance_id is a required argument' unless instance_id

      @patchboard_client
        .context
        .authorize(Context::Scheme::APPLICATION, 
          api_token: api_token, instance_id: instance_id)
      @patchboard_client
        .context
        .authorize(Context::Scheme::IDENTIFY, 
          api_token: api_token)

      self.application(app_url).refresh
    end

    def authenticate_device(email: nil, api_token: nil, user_token: nil, device_id: nil)
      @patchboard_client
        .context
        .authorize(Context::Scheme::DEVICE, 
          api_token: api_token, user_token: user_token, device_id: device_id)
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
      raise ArgumentError.new 'app_url is a required argument' unless app_url
      Application.new(resource: resources.application(app_url), client: self)
    end

    def user(email)
      raise ArgumentError.new 'email is a required argument' unless email
      User.new(resource: resources.user_query(email: email), client: self)
    end

    class Context
      module Scheme
        DEVICE = "Gem-Device"
        APPLICATION = "Gem-Application"
        IDENTIFY = "Gem-Identify"
      end

      SCHEMES = [Scheme::DEVELOPER, Scheme::DEVELOPER_SESSION,
        Scheme::DEVICE, Scheme::APPLICATION, Scheme::USER, Scheme::OTP]

      attr_accessor :schemes

      def initialize
        @schemes = {}
      end

      def authorize(scheme, params)
        raise ArgumentError, "Unknown auth scheme" unless SCHEMES.include?(scheme)
        @schemes[scheme] = params
      end

      def compile_params(params)
        if params.empty?
          # crappy alternative to raising an error when there are no params
          # TODO: probably should raise an error
          "data=none"
        else
          params.map {|key, value|
            #super hacky. but it's late.
            value.tr!('=', '') if key.eql?(:signature)
            %Q[#{key}="#{value}"]}.join(", ")
        end
      end

      def authorizer(options = {})
        schemes, resource, action, request = options.values_at(:schemes, :resource, :action, :request)
        schemes = [schemes] if schemes.is_a? String
        schemes.each do |scheme|
          if params = @schemes[scheme]
            credential = nil
            if scheme.eql?(Scheme::DEVELOPER)
              timestamp = Time.now.to_i
              params = {
                email: params[:email],
                signature: developer_signature(request[:body], params[:privkey], timestamp),
                timestamp: timestamp
              }
            end
            credential = compile_params(params)
            return [scheme, credential]
          end
        end
        raise "Action: #{action}.  No authorization available for '#{schemes}'"
      end

      def developer_signature(request_body, privkey, timestamp)
        body = request_body ? JSON.parse(request_body) : {}
        key = OpenSSL::PKey::RSA.new privkey
        content = "#{body.to_json}-#{timestamp}"
        signature = key.sign(OpenSSL::Digest::SHA256.new, content)
        Base64.urlsafe_encode64(signature)
      end

      def inspect
        # Hide the secret token when printed
        id = "%x" % (self.object_id << 1)
        %Q(#<#{self.class}:0x#{id})
      end
    end

    class UnknownKeyError < StandardError; end
    class OTPConflictError < StandardError; end

    class OTPAuthFailureError < StandardError
      attr_reader :key

      def initialize(key)
        super()
        @key = key
      end
    end


  end

end
