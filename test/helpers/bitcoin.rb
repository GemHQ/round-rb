module BitVaultTests

  module Bitcoin

    def mock_chain
      @mock_chain ||= BitVaultTests::Mockchain.new
    end

    def keypair
      @keypair ||= begin
        key = Bitcoin::Key.new
        key.generate
        key
      end
    end

    def multiwallet
      MultiWallet.generate [:primary, :backup, :cosign]
    end

    def address
      @address ||= keypair.addr
    end

    def disbursal_tx
      @disbursal_tx ||= mock_chain.disburse(address)
    end

  end

end

