require "money-tree"
require "bitcoin"

module BitVault::Bitcoin

  module Builder
    extend Bitcoin::Builder
  end

  #multi_wallet = MultiWallet.new(
    #:full => {},
    #:public => {}
  #)

  class MultiWallet

    def self.generate(names, network=:bitcoin_testnet)
      masters = {}
      names.each do |name|
        name = name.to_sym
        masters[name] = MoneyTree::Master.new(:network => network)
      end
      self.new(:full => masters)
    end

    def initialize(options)
      @full_nodes = {}
      @public_nodes = {}
      @nodes = {}
      full_nodes = options[:full]

      if !full_nodes
        raise "Must supply :full"
      end

      full_nodes.each do |name, arg|
        name = name.to_sym
        @full_nodes[name] = @nodes[name] = self.get_node(arg)
      end

      if public_nodes = options[:public]
        public_nodes.each do |name, arg|
          name = name.to_sym
          @public_nodes[name] = @nodes[name] = self.get_node(arg)
        end
      end
    end

    def drop(*names)
      names = names.map(&:to_sym)
      options = {:full => {}, :public => {}}
      @full_nodes.each do |name, node|
        unless names.include?(name.to_sym)
          options[:full][name] = node
        end
      end
      @public_nodes.each do |name, node|
        unless names.include?(name.to_sym)
          options[:full][name] = node
        end
      end
      self.class.new options
    end

    def import(addresses)
      addresses.each do |name, address|
        node = MoneyTree::Master.from_serialized_address(address)
        if node.private_key
          @full_nodes[name] = node
        else
          @public_nodes[name] = node
        end
      end
    end

    def private_address(name)
      raise "No such node: ''" unless (node = @full_nodes[name.to_sym])
      node.to_serialized_address(:private)
    end

    def public_addresses
      out = {}
      @full_nodes.each do |name, node|
        out[name] = node.to_serialized_address
      end
      out
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

    def path(path)
      options = {
        :path => path,
        :full => {},
        :public => {}
      }
      @full_nodes.each do |name, node|
        options[:full][name] = node.node_for_path(path)
      end
      @public_nodes.each do |name, node|
        options[:public][name] = node.node_for_path(path)
      end

      MultiNode.new(options)
    end


  end

  class MultiNode

    attr_reader :path, :keys, :public_keys
    def initialize(options)
      # TODO: take @m from the options
      @m = 2
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

    def script
      blob = Builder.script do |s|
        s.type :multisig
        s.recipient @m, *@public_keys.map {|name, key| key.pub }
      end
      Script.blob(blob)
    end

    def p2sh_address
      self.script.p2sh_address
    end

    def sign(name, value)
      raise "No such key: '#{name}'" unless (key = @keys[name.to_sym])
      key.sign(value) + "\x01"
    end

    def signatures(value)
      @keys.map {|name, key| self.sign(name, value)}
    end

    def add_input(tx, options)
      txin = Bitcoin::Protocol::TxIn.new
      prev_tx = options[:prev]
      index = options[:index]
      txin.prev_out = prev_tx.binary_hash
      txin.prev_out_index = index
      tx.add_in txin

      txin.sig_hash = tx.signature_hash_for_input(index, nil, self.script.blob)
      txin
    end

    def p2sh_script_sig(*signatures)
      multisig = Bitcoin::Script.to_multisig_script_sig(*signatures)
      string = Script.blob(multisig).to_s
      Bitcoin::Script.binary_from_string("#{string} #{self.script.hex}")
    end

  end


end

