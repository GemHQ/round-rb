require_relative "setup"

# For now, put the test subjects here at global scope. They can move to
# more appropriate inner scopes later
BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }

client = BV.spawn
context = client.context

users = client.resources.users
user = users.create(
  :email => "matthew@bitvault.io",
  :first_name => "Matthew",
  :last_name => "King",
  :password => "incredibly_secure"
)
# Specifying a password for a later session
client.context.password = "incredibly secure"

applications = user.applications
application = user.applications.create(
  :name => "bitcoin_emporium",
  :callback_url => "https://api.bitcoin-emporium.io/events"
)

Resources = BitVault::Client::Resources

describe "Using the BitVault API" do

  ######################################################################
  # Cache and access various test objects
  ######################################################################

  def BV
    @BV ||= BitVault::Client.discover("http://localhost:8999/") {
      BitVault::Client::Context.new
    }
  end

  def client
    @client ||= BV.spawn
  end

  def context
    @context ||= client.context
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
  # Test client creation
  ######################################################################

  describe "client.context" do

    specify "expected actions" do
      [:authorizer].each do |method|
        assert_respond_to context, method
      end

      # These are not required according to client_usage, but exist
      # in the code
      [:password, :api_token, :inspect].each do |method|
        assert_respond_to context, method
      end
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
      [:get, :update, :reset].each do |method|
        assert_respond_to user, method
      end
    end

    specify "expected attributes" do
      [:email, :first_name, :last_name, :applications].each do |method|
        assert_respond_to user, method
      end
    end

    specify "user.applications is a resource" do
      assert_kind_of Resources::Applications, user.applications
    end

    specify "expected actions" do
      [:create, :list].each do |method|
        assert_respond_to applications, method
      end
    end

  end

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

