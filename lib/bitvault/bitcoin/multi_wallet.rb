require "money-tree"
require "bitcoin"

module BitVault::Bitcoin
  include BitVault::Encodings

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
      # FIXME: must accept option for which network to use.
      @private_trees = {}
      @public_trees = {}
      @trees = {}
      private_trees = options[:private]

      if !private_trees
        raise "Must supply :private"
      end

      private_trees.each do |name, arg|
        name = name.to_sym
        @private_trees[name] = @trees[name] = self.get_node(arg)
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
      @private_trees.each do |name, node|
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
        tree = @private_trees.delete(name)
        address = tree.to_serialized_address
        @public_trees[name] = MoneyTree::Master.from_serialized_address(address)
      end
    end

    def import(addresses)
      addresses.each do |name, address|
        node = MoneyTree::Master.from_serialized_address(address)
        if node.private_key
          @private_trees[name] = node
        else
          @public_trees[name] = node
        end
      end
    end

    def private_address(name)
      raise "No such node: ''" unless (node = @private_trees[name.to_sym])
      node.to_serialized_address(:private)
    end

    def private_addresses
      out = {}
      @private_trees.each do |name, tree|
        out[name] = self.private_address(name)
      end
      out
    end

    def public_addresses
      out = {}
      @private_trees.each do |name, node|
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
      @private_trees.each do |name, node|
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

    # Takes a Transaction ready to be signed.
    #
    # Returns an Array of signature dictionaries.
    def signatures(transaction)
      transaction.inputs.map do |input|
        path = input.output.metadata[:wallet_path]
        node = self.path(path)
        sig_hash = transaction.sig_hash(input, node.script)
        node.signatures(sig_hash)
      end
    end


    # Takes a Transaction and any number of Arrays of signature dictionaries.
    # Each sig_dict in an Array corresponds to the Input with the same index.
    #
    # Uses the combined signatures from all the signers to generate and set
    # the script_sig for each Input.
    #
    # Returns the transaction.
    def authorize(transaction, *signers)
      transaction.set_script_sigs *signers do |input, *sig_dicts|
        node = self.path(input.output.metadata[:wallet_path])
        signatures = combine_signatures(*sig_dicts)
        node.script_sig(signatures)
      end
      transaction
    end

    # Takes any number of "signature dictionaries", which are Hashes where
    # the keys are tree names, and the values are base58-encoded signatures
    # for a single input.
    #
    # Returns an Array of the signatures in binary, sorted by their tree names.
    def combine_signatures(*sig_dicts)
      combined = {}
      sig_dicts.each do |sig_dict|
        sig_dict.each do |tree, signature|
          combined[tree] = decode_base58(signature)
        end
      end

      # Order of signatures is important for validation, so we always
      # sort public keys and signatures by the name of the tree
      # they belong to.
      combined.sort_by { |tree, value| tree }.map { |tree, sig| sig }
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

