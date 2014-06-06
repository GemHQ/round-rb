require 'spec_helper'

describe BitVault::Address, :vcr do
  let(:address_resource) { double('address_resource') }
  let(:address) { BitVault::Address.new(resource: address_resource) }
  
  describe 'delegated methods' do
    [:path, :string].each do |method|
      it "delegates #{method} to the resource" do
        address.resource.should_receive(method)
        address.send(method)
      end
    end
  end
end