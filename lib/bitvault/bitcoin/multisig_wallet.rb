require "money-tree"
require "bitcoin"

module BitVault::Bitcoin

  module Builder
    extend Bitcoin::Builder
  end


  class Trinode
    #attr_reader :bitvault, :live, :backup
    def initialize(options)
      @path = options[:path]
      @bitvault, @live, @backup =
        options[:nodes].values_at :bitvault, :live, :backup
      @nodes = options[:nodes]
    end

    def script
      blob = Builder.script do |s|
        s.type :multisig
        s.recipient 2, *self.pubkey_list
      end
      script = Script.blob(blob)
    end

    def p2sh_address
      self.script.p2sh_address
    end

    def p2sh_script
      self.script.p2sh_script
    end

    def pubkey_list
      self.keys.map do |name, key|
        key.pub
      end
    end

    def keys
      {
        :bitvault => Bitcoin::Key.new(@bitvault.private_key.to_hex, @bitvault.public_key.to_hex),
        :live => Bitcoin::Key.new(nil, @live.public_key.to_hex),
        :backup => Bitcoin::Key.new(nil, @backup.public_key.to_hex),
      }
    end

    def sign(kind, value)
      key = @nodes[kind].private_key
      bitcoin_key = Bitcoin::Key.from_base58 key.to_wif
      sig = bitcoin_key.sign(value)
    end

  end

  class Wallet

    def initialize(options)

      @bitvault_node = MoneyTree::Master.from_serialized_address(options[:private])
      @live_node = MoneyTree::Master.from_serialized_address options[:public][:live]
      @backup_node = MoneyTree::Master.from_serialized_address options[:public][:backup]
    end

    def trinode(path)
      Trinode.new :path => path,
        :nodes => {
          :bitvault => @bitvault_node.node_for_path(path),
          :live => @live_node.node_for_path(path),
          :backup => @backup_node.node_for_path(path),
        }
    end

  end

  #multi_wallet = MultiWallet.new(
    #:full => {},
    #:public => {}
  #)

  class MultiWallet

    def generate(names, network=:bitcoin_testnet)
      masters = {}
      names.each do |name|
        name = name.to_sym
        masters[name] = MoneyTree::Master.new(:network => network)
      end
      self.new(:full => masters)
    end

    def get_node(arg)
      case arg
      when MoneyTree::Node
        arg
      when String
        MoneyTree::Node.from_serialized_address(arg)
      else
        raise "Unusable type: #{node.class}"
      end
    end

    def initialize(options)
      @full_nodes = {}
      @public_nodes = {}
      full_nodes = options[:full]

      if !full_nodes
        raise "Must supply :full"
      end

      full_nodes.each do |name, arg|
        @full_nodes[name.to_sym] = self.get_node(arg)
      end

      if public_nodes = options[:public]
        public_nodes.each do |name, arg|
          @public_nodes[name.to_sym] = self.get_node(arg)
        end
      end
    end

  end

  class MultiNode

    attr_reader :path, :keys
    def initialize(options)
      @path = options[:path]

      @keys = {}
      @public_keys = {}
      @full = options[:full]
      @public = options[:public]

      @full.each do |name, node|
        key = Bitcoin::Key.new(node.private_key.to_hex)
        @keys[name] = key
        @public_keys[name] = key
      end
      @public.each do |name, node|
        @public_keys[name] = Bitcoin::Key.new(nil, node.public_key.to_hex)
      end
    end

    def script(m=2)
      blob = Builder.script do |s|
        s.type :multisig
        s.recipient m, *@public_keys.map {|name, key| key.pub }
      end
      BitVault::Script.blob(blob)
    end

    def p2sh_address
      self.script.p2sh_address
    end

    def p2sh_script
      self.script.p2sh_script
    end

    def signatures(value)
      @keys.map {|key| key.sign(value) }
    end

  end


end

