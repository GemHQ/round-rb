require_relative "setup"

BV = BitVault::Client.discover("http://localhost:8999/") { BitVault::Client::Context.new }
client = BV.spawn
user = client.resources.users.create :email => "matthew-#{rand(10000)}@mail.com"

exit

describe "Using the BitVault API" do
  def bitvault
    @bitvault ||= BitVault.discover "http://localhost:8999/"
  end

  describe "A user resource created with resources.users" do

    def client
      @client ||= BV.spawn
    end

    def user
      @user ||= begin
        user = client.resources.users.create(
          :email => "matthew-#{rand(10000)}@mail.com"
        )
        client.context.api_token = user.api_token
        user
      end
    end

    it "is correct type" do
      assert_kind_of BitVault::Resources::User, user
    end

    it "has expected actions" do
      assert_respond_to user, :get
      assert_respond_to user, :update
    end

    describe "user.wallets.create" do

      def cold_pubkey
      "tpubD6NzVbkrYhZ4Y4G36sgUeQWTWjSbhUXayumbyCBCyW9kheimAf5wM3qRxPvZDwUMZgwMEfzf6KSthuEChe6tm5SEtMn9gaWgbraFHcBt1Jb"
      end
      
      def hot_pubkey
      "tpubD6NzVbkrYhZ4WdKLgvETUSe8CVqaeg5QJhn78f7PvMoCmn6f94fx22c5Vm2fJz6aSuCp7tnjYC1SCczE48tAujRxoJnYDcEHuzvpMBd2SMC"
      end
  
      def wallet
        @wallet ||= begin
          user.wallets.create(
            :name => "my favorite wallet",
            :network => "bitcoin_testnet",
            :cold_pubkey => cold_pubkey,
            :hot_pubkey => hot_pubkey,
            :encrypted_hot_seed => "bogusvaluenotevenencrypted"
          )
        end
      end

      it "is correct type" do
        assert_kind_of BitVault::Resources::Wallet, wallet
      end

    end

  end

end

