class BitVault::TransactionCollection < BitVault::Collection

  def content_type
    BitVault::Transaction
  end

  def collection_type
    Array
  end

end