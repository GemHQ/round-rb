require_relative "setup"

include BitVault::Bitcoin

describe "Output" do
  include BitVaultTests::Bitcoin

  def empty_transaction
    @empty_transaction ||= Transaction.new
  end

  def script_string
    "OP_DUP OP_HASH160 7b936f13a9a2f0f2c30520c5cb24bc76a148d696 OP_EQUALVERIFY OP_CHECKSIG"
  end


  it "can be created as a standalone" do
    value = 21_000_000
    output = Output.new(:value => value, :script => script_string)
    assert_equal value, output.value
    assert_kind_of Script, output.script
  end

  it "can be created as a standalone, then associated" do
    value = 21_000_000
    output = Output.new(:value => value, :script => script_string)
    empty_transaction.add_output output
  end

end



