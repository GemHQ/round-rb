require 'spec_helper'

describe Round::Collection do
  let(:subresource) { double('subresource', name: 'foo') }
  let(:subresources) { [subresource] }
  let(:resource) { double('resource', list: subresources) }
  let(:options) { { resource: resource } }
  let(:collection) { Round::Collection.new(options) }

  describe '#initialize' do

    before(:each) {
      allow_any_instance_of(Round::Collection).to receive(:populate_data)
    }

    it 'calls populate_data' do
      collection
      expect(collection).to have_received(:populate_data).with(options)
    end

    context 'hash collection' do
      before(:each) {
        allow_any_instance_of(Round::Collection).to receive(:collection_type).and_return(Hash)
      }

      it 'instatiates collection with a Hash' do
        expect(collection.collection).to be_a_kind_of(Hash)
      end
    end

    context 'array collection' do
      before(:each) {
        allow_any_instance_of(Round::Collection).to receive(:collection_type).and_return(Array)
      }

      it 'instatiates collection with a Hash' do
        expect(collection.collection).to be_a_kind_of(Array)
      end
    end
  end

  describe '#populate_data' do
    before(:each) { allow_any_instance_of(Round::Collection).to receive(:add) }

    it 'calls add for each subresource' do
      collection
      expect(collection).to have_received(:add).once
    end
  end

  describe '#add' do
    let(:subresources) { [] }
    let(:new_subresource) { double('subresource', name: 'bar') }

    context 'hash collection' do
      before(:each) {
        allow_any_instance_of(Round::Collection).to receive(:collection_type).and_return(Hash)
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
        allow_any_instance_of(Round::Collection).to receive(:collection_type).and_return(Array)
      }

      it 'increases the count by 1' do
        expect { collection.add(new_subresource) }.to change(collection, :count).by(1)
      end

      it 'indexes the subresource by name' do
        collection.add(new_subresource)
        expect(collection).to include(new_subresource)
      end
    end
  end

  describe '#each' do
    let(:subresource) { double('subresource', name: 'some_app') }
    let(:subresources) { [subresource] }
    let(:resource) { double('resource', list: subresources) }

    context 'hash collection' do
      before(:each) {
        allow_any_instance_of(Round::Collection).to receive(:collection_type).and_return(Hash)
        allow_any_instance_of(Round::Base).to receive(:name).and_return(subresource.name)
      }

      let(:collection) { Round::Collection.new(resource: resource) }

      it 'returns the correct objects' do
        collection.each do |name, app|
          expect(app.resource).to eql(subresource)
        end
      end
    end
  end

end