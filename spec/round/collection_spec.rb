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

end