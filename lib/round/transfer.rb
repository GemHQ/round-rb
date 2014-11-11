class Round::Transfer < Round::Base

  def transaction_hash
    @resource[:hash]
  end 

end