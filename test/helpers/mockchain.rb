
module BitVaultTests
  class Mockchain

    attr_reader :chain, :mining_fee
    def initialize(options={})
      db = options[:db] || "sqlite:mockchain"

      @chain = BitVault::Bitcoin::MockChain.new :db => db
      @mining_fee = chain.coinbase_value
    end

    def transaction(recipients)
      last_transaction = @chain.last.tx.first

      transaction = Builder.build_tx do |t|
        t.input do |i|
          i.prev_out last_transaction
          i.prev_out_index 0
          i.signature_key @chain.key
        end

        recipients.each do |address, value|
          t.output do |o|
            o.value value
            o.script do |s|
              s.type :address
              s.recipient address
            end
          end
        end

      end

    end

    # Disburse the coinbase value from the last block to the supplied
    # address.  Four outputs are created:  1/2 value, 1/4, 1/8, and 1/16.
    def disburse(address)
      last_transaction = @chain.last.tx.first

      transaction = Builder.build_tx do |t|
        t.input do |i|
          i.prev_out last_transaction
          i.prev_out_index 0
          i.signature_key @chain.key
        end

        t.output do |o|
          o.value (@mining_fee / 2)
          o.script do |s|
            s.type :address
            s.recipient address
          end
        end

        t.output do |o|
          o.value (@mining_fee / 4)
          o.script do |s|
            s.type :address
            s.recipient address
          end
        end

        t.output do |o|
          o.value (@mining_fee / 8)
          o.script do |s|
            s.type :address
            s.recipient address
          end
        end

        t.output do |o|
          o.value (@mining_fee / 16)
          o.script do |s|
            s.type :address
            s.recipient address
          end
        end
      end
      # process anything here?
      transaction
    end

    # Delegate to the Mockchain when possible.
    def method_missing(name, *args, &block)
      if @chain.respond_to?(name)
        @chain.send(name, *args, &block)
      else
        super
      end
    end

  end

end
