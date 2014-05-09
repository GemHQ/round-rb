require_relative "setup"

# Why must this be here at global scope?
BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }

Resources = BitVault::Client::Resources

describe "Using the BitVault API" do

  ######################################################################
  # Cache and access various test objects
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

  def application
    @application ||= applications.create(
      :name => "bitcoin_emporium",
      :callback_url => "https://api.bitcoin-emporium.io/events"
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
  # Test applications.create
  ######################################################################

  describe "applications.create" do

    specify "correct type" do
      assert_kind_of Resources::Application, application
    end

    specify "expected actions" do
      [:get, :update, :reset, :delete].each do |method|
        assert_respond_to application, method
      end
    end

    specify "expected attributes" do
      [:name, :api_token, :owner, :wallets, :callback_url].each do |method|
        assert_respond_to application, method
      end
    end

  end

  ######################################################################
  # Test
  ######################################################################

    #describe "user.wallets.create" do

      #def wallet
        #@wallet ||= begin
          #user.wallets.create(
            #:name => "my favorite wallet",
            #:network => "bitcoin_testnet",
            #:cold_pubkey => cold_pubkey,
            #:hot_pubkey => hot_pubkey,
            #:encrypted_hot_seed => "bogusvaluenotevenencrypted"
          #)
        #end
      #end

      #it "is correct type" do
        #assert_kind_of Resources::Wallet, wallet
      #end

    #end

  #end

end

