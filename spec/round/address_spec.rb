require 'spec_helper'

describe Round::Address do
  let(:address_resource) { double('address_resource') }
  let(:address) { Round::Address.new(resource: address_resource) }
  
  describe 'delegated methods' do
    [:path, :string].each do |method|
      it "delegates #{method} to the resource" do
        expect(address.resource).to receive(method)
        address.send(method)
      end
    end
  end
end