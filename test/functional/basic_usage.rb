require_relative "setup"
include BitVault::Encodings

Resources = BitVault::Client::Resources
PassphraseBox = BitVault::Crypto::PassphraseBox
MultiWallet = BitVault::Bitcoin::MultiWallet


# Why must this be here at global scope?
BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }


describe "Using the BitVault API" do

  ######################################################################
  # Cached access to various test objects
  ######################################################################

=begin
  def BV
    @BV ||= BitVault::Client.discover("http://localhost:8999/") {
      BitVault::Client::Context.new
    }
  end
=end

  def client
    @client ||= begin
      client = BV.spawn
      client.context.password = "incredibly secure"
      client
    end
  end

  def context
    @context ||= client.context
  end

  def resources
    @resources ||= client.resources
  end

  def users
    @users ||= resources.users
  end

  def user
    @user ||= users.create(
      :email => "matthew@bitvault.io",
      :first_name => "Matthew",
      :last_name => "King",
      :password => "incredibly_secure"
    )
  end

  def applications
    @applications ||= user.applications
  end

  def application_names
    # This won't actually work while we're returning only mock data
    ["bitcoin-emporium", "bitcoin-extravaganza", "bitcoins-r-us"]
  end

  def application_list
    @application_list ||= application_names.map do |name|
      applications.create(
        :name => name,
        :callback_url => "https://api.#{name}.io/events"
      )
    end
  end

  def application
    application_list[0]
  end

  def new_wallet
    @new_wallet ||= MultiWallet.generate [:primary, :backup]
  end

  def passphrase
    "wrong pony generator brad"
  end

  def wallets
    @wallets ||= begin
      # Needed for wallets.list, wallet operations
      client.context.api_token = application.api_token
      application.wallets
    end
  end

  def wallet
    @wallet ||= begin
      primary_seed = new_wallet.trees[:primary].to_serialized_address(:private)
      encrypted_seed = PassphraseBox.encrypt(passphrase, primary_seed)
      # Must have the authentication token to create a wallet
      wallets.create(
        :name => "my favorite wallet",
        :network => "bitcoin_testnet",
        :backup_address => new_wallet.trees[:backup].to_serialized_address,
        :primary_address => new_wallet.trees[:primary].to_serialized_address,
        :primary_seed => encrypted_seed
      )
    end
  end

  def client_wallet
    @client_wallet ||=
      begin
        primary_seed = PassphraseBox.decrypt(passphrase, wallet.primary_seed)
        MultiWallet.new(
          :private => {:primary => primary_seed},
          :public =>  {:cosigner => wallet.cosigner_address,
                       :backup =>   wallet.backup_address}
        )
      end
  end

  def accounts
    @accounts ||= wallet.accounts
  end

  def account
    @account ||= accounts.create :name => "office supplies"
  end

  def addresses
    @addresses ||= account.addresses
  end

  def incoming_address
    @incoming_address ||= addresses.create
  end

  def payee
    @payee ||= begin
                 payee = Bitcoin::Key.new
                 payee.generate
                 payee
               end
  end

  def payments
    @payments ||= account.payments
  end

  def payee_address
    @payee_address ||= payee.addr
  end

  def unsigned_payment
    @unsigned_payment ||= payments.create(
      :outputs => [
        {
          :amount => 600_000,
          :payee => {:address => payee_address}
        }
      ]
    )
  end

  def transaction
    @transaction ||= BitVault::Bitcoin::Transaction.data(unsigned_payment)
  end

  def signed_payment
    @signed_payment ||= unsigned_payment.sign(
      :transaction_hash => transaction.base58_hash,
      :inputs => client_wallet.signatures(transaction)
    )
  end

  def transfers
    @transfers ||= wallet.transfers
  end

  def unsigned_transfer
    @unsigned_transfer ||= transfers.create(
      :value => 16_000,
      :memo => "running low",
      :source => "URL of source account goes here",
      :destination => "URL of destination account goes here"
    )
  end

  def transfer_transaction
    @transfer_transaction ||=
      BitVault::Bitcoin::Transaction.data(unsigned_transfer)
  end

  def signed_transfer
    @signed_transfer ||= unsigned_transfer.sign(
        :transaction_hash => transfer_transaction.base58_hash,
        :inputs => client_wallet.signatures(transfer_transaction)
    )
  end

  ######################################################################
  # Test API discovery
  ######################################################################

  describe "BitVault API discovery" do

    # N.B.: The tests reflect the API even when we know, e.g. that the function
    # exists because we called it in the code above.

    specify "expected class actions" do
      assert_respond_to BitVault::Client, :discover
    end

    specify "correct class" do
      assert_kind_of BitVault::Client, BV
    end

    specify "expected actions" do
      assert_respond_to BV, :spawn
    end
  end

  ######################################################################
  # Test client creation
  ######################################################################

  describe "client" do

    specify "correct class" do
      assert_kind_of Patchboard::Client, client
    end

    specify "expected actions" do
      [:resources, :context].each do |method|
        assert_respond_to client, method
      end
    end
  end

  ######################################################################
  # Test client context
  ######################################################################

  describe "client.context" do

    specify "expected actions" do
      [:authorizer].each do |method|
        assert_respond_to context, method
      end

      # These are not required according to client_usage.rb, but exist in the
      # code
      [:password, :api_token, :inspect].each do |method|
        assert_respond_to context, method
      end
    end
  end

  ######################################################################
  # Test client resources
  ######################################################################

  describe "client.resources" do

    specify "expected actions" do
      assert_respond_to resources, :users
    end
  end

  ######################################################################
  # Test users resource
  ######################################################################

  describe "client.resources.users" do

    specify "expected actions" do
      assert_respond_to client.resources.users, :create
    end
  end

  ######################################################################
  # Test users.create
  ######################################################################

  describe "users.create" do

    specify "correct type" do
      assert_kind_of Resources::User, user
    end

    specify "expected actions" do
      [:get, :update, :reset].each do |method|
        assert_respond_to user, method

      end

      # TODO: add tests of each method
      assert_kind_of Resources::User, user.get
    end

    specify "expected attributes" do
      [:email, :first_name, :last_name, :applications].each do |method|
        assert_respond_to user, method
      end
    end

  end

  ######################################################################
  # Test applications resource
  ######################################################################

  describe "applications" do

    specify "user.applications is a resource" do
      assert_kind_of Resources::Applications, applications
    end

    specify "expected actions" do
      [:create, :list].each do |method|
        assert_respond_to applications, method
      end
    end

  end

  ######################################################################
  # Test applications methods
  ######################################################################

  describe "test applications.create, applications.list" do

    specify "correct type" do

      application_list.each do |app|
        assert_kind_of Resources::Application, app
      end

      # Here so that we know that the applications have been created

      # the below is for the future, it won't work while the server
      # is returning mock data.

      #assert_equal applications.list.length, application_list.length
      assert_equal applications.list.length, 1

      applications.list.each do |app|
        assert_kind_of Resources::Application, app
      end
    end

  end

  ######################################################################
  # Test application methods
  ######################################################################

  describe "test application methods" do

    specify "expected actions" do
      [:get, :update, :reset, :delete].each do |method|
        application_list.each do |app|
          assert_respond_to app, method
        end
      end

      # TODO: test each method
      application_list.each do |app|
        assert_kind_of Resources::Application, app.get
      end
    end

    specify "expected attributes" do
      [:name, :api_token, :owner, :wallets, :callback_url].each do |method|
        application_list.each do |app|
          assert_respond_to app, method
        end
      end
    end

    specify "test application.update" do

      application_list.each do |app|
        app.update(:name => app.name + "-updated")
      end

      # TODO: after mock-data, check that the names are changed
    end

    specify "test application.reset" do

      # No actual reset with mock data
      application_list.each do |app|
          reset = app.reset
          assert_kind_of Resources::Application, reset
          assert_respond_to reset, :api_token
          refute_equal reset.api_token, app.api_token
      end
    end

    specify "test application.delete" do

      # No actual reset with mock data
      application_list.each do |app|
        app.delete
      end

      # TODO: after mock-data, test that they were deleted
    end

  end

  ######################################################################
  # Test wallets resource
  ######################################################################

  describe "test application.wallets" do

    specify "correct type" do

      assert_kind_of Resources::Wallets, wallets
    end

    specify "expected actions" do
      [:create, :list].each do |method|
        assert_respond_to wallets, method
      end
    end

  end

  ######################################################################
  # Test MultiWallet creation
  ######################################################################

  describe "test MultiWallet creation" do

    specify "MultiWallet.generate" do
      assert_kind_of MultiWallet, new_wallet
    end
  end

  ######################################################################
  # Test wallet creation
  ######################################################################

  describe "test wallet creation" do
    specify "correct type" do
      assert_kind_of Resources::Wallet, wallet
    end

    specify "expected actions" do
      [:get].each do |method|
        assert_respond_to wallet, method
      end

      # TODO: test each method
      assert_kind_of Resources::Wallet, wallet.get
    end

    specify "test wallets.list" do

      assert_equal wallets.list.length, 1
      wallets.list.each do |wallet|
        assert_kind_of Resources::Wallet, wallet
      end
    end
  end

  ######################################################################
  # Test accounts resource
  ######################################################################

  describe "test wallet.accounts resource" do

    specify "correct type" do

      assert_kind_of Resources::Accounts, accounts
    end

    specify "expected actions" do
      [:create, :list].each do |method|
        assert_respond_to accounts, method
      end
    end

  end

  ######################################################################
  # Test account creation
  ######################################################################

  describe "test account creation" do

    specify "correct type" do
      assert_kind_of Resources::Account, account
    end

    specify "expected actions" do
      [:get, :update].each do |method|
        assert_respond_to account, method
      end

      # TODO: test each method
      assert_kind_of Resources::Account, account.get

      assert_kind_of Resources::Account, account.update(:name => "rubber bands")
    end

    specify "accounts.list" do

      assert_equal accounts.list.length, 1

      accounts.list.each do |acct|
        assert_kind_of Resources::Account, account
      end
    end

  end

  ######################################################################
  # Test addresses resource
  ######################################################################

  describe "test account.addresses resource" do

    specify "correct type" do

      assert_kind_of Resources::Addresses, addresses
    end

    specify "expected actions" do
      [:create].each do |method|
        assert_respond_to addresses, method
      end
    end

  end

  ######################################################################
  # Test address creation
  ######################################################################

  describe "test address creation" do

    specify "correct type" do
      assert_kind_of Hashie::Mash, incoming_address
    end

  end

  ######################################################################
  # Test payee creation
  ######################################################################

  describe "test payee creation" do

    specify "correct type" do

      assert_kind_of Bitcoin::Key, payee
    end

    specify "expected actions" do

      [:addr].each do |method|
        assert_respond_to payee, method
      end
    end

  end

  ######################################################################
  # Test payments resource
  ######################################################################

  describe "test payments resource" do

    specify "correct type" do

      assert_kind_of Resources::Payments, payments
    end

    specify "expected actions" do
      [:create].each do |method|
        assert_respond_to payments, method
      end
    end

  end

  ######################################################################
  # Test unsigned_payment creation
  ######################################################################

  describe "test unsigned_payment creation" do

    specify "correct type" do

      assert_kind_of Resources::UnsignedPayment, unsigned_payment
    end

    specify "expected actions" do

      [:sign].each do |method|
        assert_respond_to unsigned_payment, method
      end
    end

  end

  ######################################################################
  # Test transaction creation
  ######################################################################

  describe "test transaction creation" do

    specify "correct type" do

      assert_kind_of BitVault::Bitcoin::Transaction, transaction
    end

    specify "expected resources" do

      [:outputs].each do |method|
        assert_respond_to transaction, method
      end
    end

    specify "valid change address" do
      assert client_wallet.valid_output?(transaction.outputs.last)
    end

  end

  ######################################################################
  # Test transaction signing
  ######################################################################

  describe "test transaction signing" do

    specify "correct type" do

      assert_kind_of Hashie::Mash, signed_payment
    end

  end

  ######################################################################
  # Test transfers resource
  ######################################################################

  describe "test transfers resource" do

    specify "correct type" do

      assert_kind_of Resources::Transfers, transfers
    end

    specify "expected actions" do

      [:create].each do |method|
        assert_respond_to transfers, method
      end
    end

  end

  ######################################################################
  # Test transfer creation
  ######################################################################

  describe "test transfer creation" do

    specify "create unsigned transfer" do

      assert_kind_of Resources::UnsignedTransfer, unsigned_transfer
    end

    specify "expected actions" do

      [:sign].each do |method|
        assert_respond_to unsigned_transfer, method
      end
    end

  end

  ######################################################################
  # Test transfer transaction reconstruction
  ######################################################################

  describe "test transfer transaction reconstruction" do

    specify "reconstruct transfer transaction" do

      assert_kind_of BitVault::Bitcoin::Transaction, transfer_transaction
    end

    specify "valid source address" do
      assert client_wallet.valid_output?(
        transfer_transaction.inputs.first.output
      )
    end

    specify "valid destination address" do
      assert client_wallet.valid_output?(transfer_transaction.outputs.last)
    end

  end

  ######################################################################
  # Test transfer signing
  ######################################################################

  describe "test transfer signing" do

    specify "sign transfer" do

      assert_kind_of Hashie::Mash, signed_transfer
    end

  end

end

