require 'spec_helper'

describe BitVault::Collection do
  let(:subresource) { double('subresource', name: 'foo') }
  let(:subresources) { [subresource] }
  let(:resource) { double('resource', list: subresources) }
  let(:options) { { resource: resource } }
  let(:collection) { BitVault::Collection.new(options) }

  describe '#initialize' do
    before(:each) {
      BitVault::Collection.any_instance.stub(:populate_data)
    }

    it 'calls populate_data' do
      BitVault::Collection.any_instance.should_receive(:populate_data).with(options)
      collection
    end

    context 'hash collection' do
      before(:each) {
        BitVault::Collection.any_instance.stub(:collection_type).and_return(Hash)
      }

      it 'instatiates collection with a Hash' do
        expect(collection.collection).to be_a_kind_of(Hash)
      end
    end

    context 'array collection' do
      before(:each) {
        BitVault::Collection.any_instance.stub(:collection_type).and_return(Array)
      }

      it 'instatiates collection with a Hash' do
        expect(collection.collection).to be_a_kind_of(Array)
      end
    end
  end

  describe '#populate_data' do
    before(:each) { BitVault::Collection.any_instance.stub(:add) }

    it 'calls add for each subresource' do
      BitVault::Collection.any_instance.should_receive(:add).once
      collection
    end
  end

  describe '#add' do
    let(:subresources) { [] }
    let(:new_subresource) { double('subresource', name: 'bar') }

    context 'hash collection' do
      before(:each) {
        BitVault::Collection.any_instance.stub(:collection_type).and_return(Hash)
      }

      it 'increases the count by 1' do
        expect { collection.add(new_subresource) }.to change(collection, :count).by(1)
      end

      it 'indexes the subresource by name' do
        collection.add(new_subresource)
        expect(collection['bar']).to eql(new_subresource)
      end
    end

    context 'array collection' do
      before(:each) {
        BitVault::Collection.any_instance.stub(:collection_type).and_return(Array)
      }

      it 'increases the count by 1' do
        expect { collection.add(new_subresource) }.to change(collection, :count).by(1)
      end

      it 'indexes the subresource by name' do
        collection.add(new_subresource)
        expect(collection.include?(new_subresource)).to be_true
      end
    end
  end

end