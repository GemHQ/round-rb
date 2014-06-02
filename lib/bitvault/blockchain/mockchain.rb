require "bitcoin"

Bitcoin::NETWORKS[:mockchain] = {
  :project => :bitcoin,
  :magic_head => "mock",
  :address_version => "6f",
  :p2sh_version => "c4",
  :privkey_version => "ef",
  :default_port => 48333,
  :protocol_version => 70001,
  :max_money => 21_000_000 * 100_000_000,
  :dns_seeds => [],
  :genesis_hash => "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
  :proof_of_work_limit => 553713663,
  :alert_pubkeys => [],
  :known_nodes => [],
  :checkpoints => {}
}

Bitcoin.network = :mockchain


module CoinOp::Bit

  class MockChain
    include ::Bitcoin::Builder

    attr_reader :key, :store, :last, :coinbase_value

    def initialize(config={})
      @key = Bitcoin::Key.new
      @key.generate
      @config = config
      @coinbase_value = 50e8

      if @config[:db]
        @store = Bitcoin::Storage.sequel(
          :db => @config[:db], :log_level => :warn
        )
        @store.connect
        if head = @store.get_head
          @last = head
        else
          self.reset
        end
      else
        self.reset
      end
    end

    def reset
      @store.reset if @store
      @block0 = self.add :key => @key, :previous => "00"*32

      Bitcoin.network[:genesis_hash] = @block0.hash
      @store.store_block(@block0) if @store
      @last = @block0
    end

    def mine(key=nil)
      key ||= @key
      block = self.add :key => key, :previous => @last.hash
    end

    def add(options={})
      if !options[:key]
        raise "Must provide :key"
      end
      options[:bits] ||= Bitcoin.network[:proof_of_work_limit]
      previous_block = options[:previous] || @last

      block = build_block(Bitcoin.decode_compact_bits(options[:bits])) do |b|
        b.time options[:time] if options[:time]
        b.prev_block previous_block
        b.tx do |t|
          t.input {|i| i.coinbase }
          t.output do |o|
            o.value @coinbase_value
            o.script {|s| s.recipient options[:key].addr }
          end
        end
      end
      if options[:transactions]
        options[:transactions].each do |transaction|
          block.tx << transaction
        end
      end

      @store.store_block(block) if @store
      @last = block
      block
    end

    def transaction(recipients)
      last_transaction = @last.tx.first

      transaction = Builder.build_tx do |t|
        t.input do |i|
          i.prev_out last_transaction
          i.prev_out_index 0
          i.signature_key @key
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


  end

end

