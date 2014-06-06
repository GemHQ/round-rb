require 'spec_helper'

describe BitVault::AddressCollection, :vcr do
  let(:address_collection_resource) { double('address_collection_resource', list: []) }
  let(:address_collection) { BitVault::AddressCollection.new(resource: address_collection_resource) }
  let(:address_resource) { double('address_resource') }

  describe '#create' do
    before(:each) {
      address_collection.resource.stub(:create).and_return(address_resource)
    }

    let(:address) { address_collection.create }

    it 'delegates to the resource' do
      address_collection.resource.should_receive(:create)
      address
    end

    it 'returns an address object' do
      expect(address).to be_a_kind_of(BitVault::Address)
    end

    it 'increases the address count' do
      expect { address }.to change(address_collection, :count).by(1)
    end
  end
end