require "pp"
require "rbnacl"
require "openssl"

module BitVault
  class Client

    class Passphrase

      attr_reader :salt, :key
      def initialize(passphrase, salt=nil)
        @salt = salt || RbNaCl::Random.random_bytes(16)
        @key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          passphrase, @salt,
          100_000, # number of iterations
          32      # key length in bytes
        )
      end

    end

  end
end

