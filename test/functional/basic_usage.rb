require_relative "setup"

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn
context = client.context
users = client.resources.users
user = users.create :email => "matthew-#{rand(10000)}@mail.com"
client.context.password = "incredibly secure"
applications = user.applications
application = user.applications.create(
  :name => "bitcoin_emporium",
  :callback_url => "https://api.bitcoin-emporium.io/events"
)

Resources = BitVault::Client::Resources


describe "Using the BitVault API" do

  describe "BitVault::Client" do

    specify "expected actions" do
      assert_respond_to BitVault::Client, :discover
    end
  end

  describe "BV" do

    specify "correct class" do
      assert_kind_of BitVault::Client, BV
    end

    specify "expected actions" do
      assert_respond_to BV, :spawn
    end
  end

  describe "context" do

    specify "expected actions" do
      assert_respond_to context, :authorizer
      assert_respond_to context, :password
      assert_respond_to context, :api_token
      assert_respond_to context, :inspect
    end
  end

  describe "client" do

    specify "expected actions" do
      assert_respond_to client, :resources
    end
  end

  describe "client.resources" do

    specify "expected actions" do
      assert_respond_to client.resources, :users
    end
  end

  describe "client.resources.users" do

    specify "expected actions" do
      assert_respond_to client.resources.users, :create
    end
  end

  describe "users.create" do

    specify "correct type" do
      assert_kind_of Resources::User, user
    end

    specify "expected actions" do
      assert_respond_to user, :get
      assert_respond_to user, :update
      assert_respond_to user, :reset
    end

    specify "expected attributes" do
      [:email, :first_name, :last_name, :applications].each do |method|
        assert_respond_to user, method
      end
    end

    specify "user.applications is a resource" do
      assert_kind_of Resources::Applications, user.applications
    end

  end

  describe "applications.create" do

    specify "correct type" do
      assert_kind_of Resources::Application, application
    end

    specify "expected actions" do
      assert_respond_to application, :get
      assert_respond_to application, :update
    end

    specify "expected attributes" do
      [:name, :api_token, :owner, :wallets, :callback_url].each do |method|
        assert_respond_to application, method
      end
    end

    #specify "user.applications is a resource" do
      #assert_kind_of Resources::Applications, user.applications
    #end

  end

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

