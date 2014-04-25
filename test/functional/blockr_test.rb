require_relative "setup"

require "bitvault/blockchain/blockr"

describe "Blockr.io interface" do

  def blockr
    BitVault::Blockchain::Blockr.new "test"
  end

  it "can query unspent outputs" do
    result = blockr.unspent %w[
      n4rYhkv1LgtbXaXuFNCgG1hATJJTSec8F5
      n4rYhdx8CGo5fSVGh3jpfPhdHvJu6U7EQo
      n4rYdFbkiLSTdQ3uWsG7C46nikJmHjvhuV
    ]
    puts JSON.pretty_generate(result)
  end

end



