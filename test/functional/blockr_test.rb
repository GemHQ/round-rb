require_relative "setup"

include BitVault::Encodings

require "bitvault/blockchain/blockr"

describe "Blockr.io interface" do

  def blockr
    BitVault::Blockchain::Blockr.new "test"
  end

  before do
    @address_list = %w[
      mfuQGZT7AFQoSEeUnqwQwuzMnzUctfmLsp
      mnUarZY2MdEXZms2wPriz6dsdmc56x4yy6
      ms85owo6iJ7RAR9yyPDMTbpWaeBmvMhnQ8
      muoKegNRY2bqbBnjWyfk6vEGYy1VF1WDWU
      mh4Xvw7ULwZjWJBDuX37a8w4aJnqZ7XHre
      mhEnZWwxyjMPynwhaVyAsmwdthsayUj7as
      mhfBNhQ3mL4mWtBd1d1HX3GxZd5g8uJ2h5
      mnqoYj21B8feCxtn8RRgW7zWHBSSHrDrvC
      mxmYCw1TT4dZwb8u56beBdzbdm11Wa8pYv
      n1rXU5vMP4LvJaw84D9i9wsAscp4MGCS8U
      mjb1QAXWWYdQNcEHrqBAWXvcbHb9eeKGhE
      mkGStGBXiUTkbVD24j1zPw3gkbGckBpxTk
      n1extCoVFdXbdQueY8U7Tq6s2rubeH6ALz
      n2pn3y1WRRj48f7ir4PyAPVYXSswm2fQif
      mjPJaiLRQro8sZNcDJuRivMM2E4uMW86Xq
      mxpwVrLnrngnUSgXSWGSYncUK7YHT3SP7f
    ]

    @transaction_list = %w[
      bb95da3bc61a72016a96c6a6e09934d822ff8ce67126920ec214d0c2fbb41c62
      49d4131a3bd5436a7a3fbbca6f4abc278f7f44ede375a702dcfe5411599c2053
      48e9a6657f0b4121bd4c95ca461959f33741a921b727453ecf24267b6ea01d0c
      5f9efe545125b0422f3c7146a0496a7426e3f1daefcd1cea5c3e5a4e056060f7
      e972d276c6178075a8dfd0eed40a861d8b3a26d48d9fa82b0fe093c8bd5fc870
      3c4ae22c21a5da536989c3eb943d9279123a32e76df06f0b896bc80ca8266760
      ca81061a5d883fce3175b349fd9d13c7e5b2a27095b7a792d52dce078eb1dc02
      30a12cabb2e97b76334b08ab288fe12138062890128b98cf07736277d8e78c05
      f5719f9b188a1fe30ebac9333842342ec44cfc816125321f244d6c0ab6cafbee
      ab24bc7e153d479e16e6d893b8075cd698eef09c1515a9e1c138f5f19c99f467
      0f0e5a04023cf1a2a8dfc794b1a343c4c40155678afc6f0b3c2d4df723e54bb7
      20a9f42e7966965e6c731743a7cf6d246e5f0dac09bb1e97917423bb3d803992
      9dcac65756ede49d318b5139544294c113fb37c23845e2c0d2cdc681be86383f
    ]
  end

  it "can query unspent outputs" do

    result = blockr.unspent @address_list

    assert_kind_of Array, result

    result.each do |output|
      assert_kind_of BitVault::Bitcoin::Output, output
    end

    output = result[0]

    assert_equal(
      # TODO:
      # transaction hashes should be hex, not base58.
      # https://github.com/BitVault/bitvault-rb/issues/1
      "BcxLvpD8cYB7qQwy9Hg8KcjM1nfD4M4XrFSkn8TTk7RY",
      base58(output.transaction_hash)
    )

    assert_equal 0, output.index
    assert_equal 1000000000, output.value
  end


  # Test Blocker#balance
  it "can query balance by address list" do

    balances = blockr.balance @address_list

    puts JSON.pretty_generate(balances)
  end


  # Test Blocker#balance
  it "can query with a one-element address list" do

    balance = blockr.balance [ "mfuQGZT7AFQoSEeUnqwQwuzMnzUctfmLsp" ]
    puts JSON.pretty_generate(balance)
  end


  # Test Blocker#balance
  it "can query balance by single address" do

    balance = blockr.balance "mfuQGZT7AFQoSEeUnqwQwuzMnzUctfmLsp"
    puts JSON.pretty_generate(balance)
  end


  # Test Blocker#transactions
  it "can query transaction info" do

    # This is very verbose
    puts JSON.pretty_generate blockr.transactions @transaction_list
  end

end
