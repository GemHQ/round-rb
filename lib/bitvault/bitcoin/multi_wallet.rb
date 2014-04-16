require "money-tree"
require "bitcoin"

module BitVault::Bitcoin

  module Builder
    extend Bitcoin::Builder
  end

  class MultiWallet

    def self.generate(names, network=:bitcoin_testnet)
      masters = {}
      names.each do |name|
        name = name.to_sym
        masters[name] = MoneyTree::Master.new(:network => network)
      end
      self.new(:private => masters)
    end

    attr_reader :trees

    def initialize(options)
      @full_trees = {}
      @public_trees = {}
      @trees = {}
      full_trees = options[:private]

      if !full_trees
        raise "Must supply :private"
      end

      full_trees.each do |name, arg|
        name = name.to_sym
        @full_trees[name] = @trees[name] = self.get_node(arg)
      end

      if public_trees = options[:public]
        public_trees.each do |name, arg|
          name = name.to_sym
          @public_trees[name] = @trees[name] = self.get_node(arg)
        end
      end
    end

    def drop(*names)
      names = names.map(&:to_sym)
      options = {:private => {}, :public => {}}
      @full_trees.each do |name, node|
        unless names.include?(name.to_sym)
          options[:private][name] = node
        end
      end
      @public_trees.each do |name, node|
        unless names.include?(name.to_sym)
          options[:private][name] = node
        end
      end
      self.class.new options
    end

    def drop_private(*names)
      names.each do |name|
        name = name.to_sym
        tree = @full_trees.delete(name)
        address = tree.to_serialized_address
        @public_trees[name] = MoneyTree::Master.from_serialized_address(address)
      end
    end

    def import(addresses)
      addresses.each do |name, address|
        node = MoneyTree::Master.from_serialized_address(address)
        if node.private_key
          @full_trees[name] = node
        else
          @public_trees[name] = node
        end
      end
    end

    def private_address(name)
      raise "No such node: ''" unless (node = @full_trees[name.to_sym])
      node.to_serialized_address(:private)
    end

    def public_addresses
      out = {}
      @full_trees.each do |name, node|
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
        :private => {},
        :public => {}
      }
      @full_trees.each do |name, node|
        options[:private][name] = node.node_for_path(path)
      end
      @public_trees.each do |name, node|
        options[:public][name] = node.node_for_path(path)
      end

      MultiNode.new(options)
    end

    def valid_output?(output)
      if path = output.metadata.wallet_path
        node = self.path(path)
        node.p2sh_script.to_s == output.script.to_s
      else
        true
      end
    end

    def signatures(transaction)
      transaction.inputs.map do |input|
        path = input.output.metadata[:wallet_path]
        node = self.path(path)
        sig_hash = transaction.sig_hash(input, node.script)
        node.signatures(sig_hash)
      end
    end

  end

  class MultiNode

    attr_reader :path, :keys, :public_keys
    def initialize(options)
      # m of n 
      # TODO: take @m from the options
      @m = 2
      @path = options[:path]

      @keys = {}
      @public_keys = {}
      @private = options[:private]
      @public = options[:public]

      @private.each do |name, node|
        key = Bitcoin::Key.new(node.private_key.to_hex, node.public_key.to_hex)
        @keys[name] = key
        @public_keys[name] = key
      end
      @public.each do |name, node|
        @public_keys[name] = Bitcoin::Key.new(nil, node.public_key.to_hex)
      end
    end

    def script
      keys = @public_keys.sort_by {|name, key| name }.map {|name, key| key.pub }
      Script.new(:public_keys => keys, :needed => @m)
    end

    def p2sh_address
      self.script.p2sh_address
    end

    def p2sh_script
      Script.new(:address => self.script.p2sh_address)
    end

    def sign(name, value)
      raise "No such key: '#{name}'" unless (key = @keys[name.to_sym])
      # \x01 means the hash type is SIGHASH_ALL
      # https://en.bitcoin.it/wiki/OP_CHECKSIG#Hashtype_SIGHASH_ALL_.28default.29
      key.sign(value) + "\x01"
    end

    def signatures(value)
      out = {}
      @keys.each do |name, key|
        out[name] = base58(self.sign(name, value))
      end
      out
    end

    def script_sig(signatures)
      self.script.p2sh_sig(:signatures => signatures)
    end

  end


end

