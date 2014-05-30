require "patchboard"
require_relative "crypto"
require "base64"

module BitVault

  class Client < Patchboard

    # Create a namespace for the resource classes that will be automatically
    # created by Patchboard.

    def self.discover(url)
      super url, :namespace => self::Resources
    end

    module Resources; end

    # A class providing the `authorizer` method to allow for distinct
    # authentication contexts.  This may later be useful for many
    # other purposes.  It will be used in Patchboard#spawn, which
    # returns a "sub-client".
    class Context
      attr_accessor :email, :password, :api_token

      def set_basic(email, password)
        @basic = Base64.encode64("#{email}:#{password}").gsub("\n", "")
      end

      def set_token(api_token)
        @api_token = api_token
      end

      # Provided with the authentication scheme for an Authorization
      # header, the resource instance on which an action is being called,
      # and the name of the action, the `authorizer` method returns
      # the credential to be used for the Authorization header value.
      #
      # This particular Context class, obviously, isn't doing anything
      # fancy with the authorizer.  More advanced applications, though,
      # can reflect on the arguments to do very granular authorization.
      def authorizer(scheme, resource, action)
        case scheme
        when "Basic"
          raise "Must call set_basic(email, password) first" unless @basic
          @basic
        when "BitVault-Token"
          raise "Must call set_token(api_token) first" unless @api_token
          @api_token
        end
      end

      def inspect
        # Hide the secret token when printed
        id = "%x" % (self.object_id << 1)
        %Q(#<#{self.class}:0x#{id})
      end
    end

  end

end

