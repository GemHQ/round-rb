require 'spec_helper'

describe BitVault::Address, :vcr do
  let(:client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:application) { client.user.applications['bitcoin_app'] }
  let(:account) { application.wallets['my funds'].accounts['office supplies'] }
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