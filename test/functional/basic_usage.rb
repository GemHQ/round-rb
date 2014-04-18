require_relative "setup"

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn
user = client.resources.users.create :email => "matthew-#{rand(10000)}@mail.com"

Resources = BitVault::Client::Resources


describe "Using the BitVault API" do

  def client
    @client ||= BV.spawn
  end

  def user
    @user ||= begin
      user = client.resources.users.create(
        :email => "matthew-#{rand(10000)}@mail.com"
      )
      client.context.password = "incredibly secure"
      user
    end
  end

  def application
    @application ||= begin
      user.applications.create(
        :name => "bitcoin_emporium",
        :callback_url => "https://api.bitcoin-emporium.io/events"
      )
    end
  end

  describe "users.create" do

    specify "correct type" do
      assert_kind_of Resources::User, user
    end

    specify "expected actions" do
      assert_respond_to user, :get
      assert_respond_to user, :update
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

