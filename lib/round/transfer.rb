module Round
  class Transfer < Round::Base

    def transaction_hash
      @resource[:hash]
    end 

  end
end