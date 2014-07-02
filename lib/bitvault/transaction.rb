class BitVault::Transaction < BitVault::Base
  def_delegators :@resource, :data, :type
end