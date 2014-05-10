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

        # TODO: add tests of each method
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
  # Test applications methods
  ######################################################################

  describe "applications.create, applications.list" do

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

  ######################################################################
  # Test application methods
  ######################################################################

    specify "expected actions" do
      [:get, :update, :reset, :delete].each do |method|
        application_list.each do |app|
          assert_respond_to app, method
        end
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

      # TODO: post-mock data, check that the names are changed
    end

    specify "test application.reset" do

      reset = application.reset
      assert_respond_to reset, :api_token
    end

    specify "test application.delete" do

      application_list.each do |app|
        app.delete
      end

      # TODO: post mock-data, test that they were deleted
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

