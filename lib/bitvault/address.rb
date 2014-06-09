class BitVault::Address < BitVault::Base
  def_delegators :@resource, :path, :string  
end