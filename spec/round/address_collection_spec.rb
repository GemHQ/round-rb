require 'spec_helper'

describe Round::AddressCollection do
  let(:address_collection_resource) { double('address_collection_resource', list: [], create: address_resource) }
  let(:address_collection) { Round::AddressCollection.new(resource: address_collection_resource) }
  let(:address_resource) { double('address_resource') }

  describe '#create' do
    let(:address) { address_collection.create }

    it 'delegates to the resource' do
      expect(address_collection.resource).to receive(:create)
      address
    end

    it 'returns an address object' do
      expect(address).to be_a_kind_of(Round::Address)
    end

    it 'increases the address count' do
      expect { address }.to change(address_collection, :count).by(1)
    end
  end
end