class BitVault::Wallet < BitVault::Base
  extend Forwardable

  def_delegators :@resource, :name

  def accounts
    @accounts ||= BitVault::AccountCollection.new(resource: @resource.accounts, wallet: self)
    @accounts
  end

end