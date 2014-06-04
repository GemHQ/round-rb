require 'spec_helper'

describe BitVault::Address, :vcr do
  let(:authed_client) {
    BitVault::Patchboard.authed_client(app_url: 'http://localhost:8999/apps/jeZgADLToHXD5PDziaMk2g', 
      api_token: '9X7axU2VU36ssm4MoVN8rNjQBFVL2iLoM1VRFvlLyBM')
  }
  let(:account) { authed_client.application.wallets[0].accounts.last }
  let(:address) { account.addresses[0] }
  
  describe 'delegated methods' do
    [:path, :string].each do |method|
      it "delegates #{method} to the resource" do
        address.resource.should_receive(method)
        address.send(method)
      end
    end
  end
end