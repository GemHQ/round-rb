module Round
  class TransactionCollection < Round::Collection

    def content_type
      Round::Transaction
    end

    def collection_type
      Array
    end

  end
end