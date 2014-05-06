require_relative "setup"

include BitVault::Crypto

# TODO: more vigorous and rigorous testing.

describe "PassphraseBox" do

  describe ".encrypt(passphrase, plaintext)" do

    it "returns a Hash containing ciphertext, nonce, and salt" do
      passphrase, plaintext = "some good passphrase", "keep this string secret"
      hash = PassphraseBox.encrypt(passphrase, plaintext)
      assert_equal [:ciphertext, :iterations, :nonce, :salt], hash.keys.sort
      refute_equal passphrase, hash[:ciphertext]
    end

  end

  describe ".decrypt(passphrase, hash)" do

    it "returns the plaintext using the hash produced by .encrypt" do
      passphrase, plaintext = "some good passphrase", "keep this string secret"
      hash = PassphraseBox.encrypt(passphrase, plaintext)
      decrypted = PassphraseBox.decrypt(passphrase, hash)
      assert_equal plaintext, decrypted
    end

  end

end

