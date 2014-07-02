class BitVault::Transfer < BitVault::Base

  def transaction_hash
    @resource[:hash]
  end 

end