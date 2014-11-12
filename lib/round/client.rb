require "patchboard"
require "base64"

module Round

  def self.url
    "https://api.gem.co"
  end

  def self.client(url=nil)
    url ||= Round.url
    @patchboard ||= ::Patchboard.discover(url) { Client::Context.new }
    Client.new(url, @patchboard)
  end

  class Client

    def initialize(url, patchboard)
      @url = url
      @patchboard_client = patchboard.spawn
    end

    def authenticate(options)

    end

    def authenticate_user(options)

    end

    def authenticate_application(options)

    end

    def authenticate_developer(email, privkey)
      @patchboard_client.context.authorize(Context::Scheme::DEVELOPER, email: email, privkey: privkey)
    end

    def resources
      @patchboard_client.resources
    end

    def developers
      @developers ||= DeveloperCollection.new(resource: resources.developers)
    end

    def users
      @users ||= UserCollection.new(resource: resources.users)
    end

    class Context
      module Scheme
        DEVELOPER = "Gem-Developer"
        DEVELOPER_SESSION = "Gem-Developer-Session"
        DEVICE = "Gem-Device"
        APPLICATION = "Gem-Application"
        USER = "Gem-User"
        OTP = "Gem-OOB-OTP"
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

      def authorizer(schemes, resource, action)
        schemes = [schemes] if schemes.is_a? String
        schemes.each do |scheme|
          if params = @schemes[scheme]
            credential = nil
            if scheme.eql?(Scheme::DEVELOPER)
              credential = developer_signature(request[:body], params[:privkey])
            else
              credential = compile_params(params)
            end
            return [scheme, credential]
          end
        end
        raise "Action: #{action}.  No authorization available for '#{schemes}'"
      end

      def developer_signature(request_body, privkey)
        
      end

      def inspect
        # Hide the secret token when printed
        id = "%x" % (self.object_id << 1)
        %Q(#<#{self.class}:0x#{id})
      end
    end
  end

end

