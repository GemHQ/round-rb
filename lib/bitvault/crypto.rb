require "rbnacl"
require "openssl"

module BitVault
  module Crypto

    class PassphraseBox
      include BitVault::Encodings
      extend BitVault::Encodings

      # Given passphrase and plaintext as strings, returns a Hash
      # containing the ciphertext and other values needed for later
      # decryption.
      def self.encrypt(passphrase, plaintext)
        box = self.new(passphrase)
        box.encrypt(plaintext)
      end

      # PassphraseBox.decrypt "my great password",
      #   :salt => salt, :nonce => nonce, :ciphertext => ciphertext
      #
      def self.decrypt(passphrase, hash)
        salt, nonce, ciphertext =
          hash.values_at(:salt, :nonce, :ciphertext).map {|s| decode_base58(s) }
        box = self.new(passphrase, salt)
        box.decrypt(nonce, ciphertext)
      end

      attr_reader :salt

      def initialize(passphrase, salt=nil)
        @salt = salt || RbNaCl::Random.random_bytes(16)
        key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          passphrase, @salt,
          10_000, # number of iterations
          32      # key length in bytes
        )
        @box = RbNaCl::SecretBox.new(key)
      end

      def encrypt(plaintext)
        nonce = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.nonce_bytes)
        ciphertext = @box.encrypt(nonce, plaintext)
        {
          :salt => base58(@salt),
          :nonce => base58(nonce),
          :ciphertext => base58(ciphertext)
        }
      end

      def decrypt(nonce, ciphertext)
        @box.decrypt(nonce, ciphertext)
      end

    end

  end
end
