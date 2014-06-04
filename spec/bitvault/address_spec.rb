require 'spec_helper'

describe BitVault::Address, :vcr do
  let(:authed_client) {
    BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/9foNkOXAx5o-jZKx672EAQ',
      api_token: 'j5kiETM6ZD0PAkybkHqagqT_S2zwRWUfe9Sn-o2Bwkg')
  }
  let(:account) { authed_client.application.wallets[0].account[0] }
  let(:address) { account.addresses[0] }
  
  describe 'delegated methods' do
    [:path, :string].each do |method|
      it "delegates #{method} to the resource" do

      end
    end
  end
end