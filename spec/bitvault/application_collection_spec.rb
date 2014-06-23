require 'spec_helper'

describe BitVault::ApplicationCollection do
  let(:applications_resource) { double('applications_resource', list: []) }
  let(:application_collection) { BitVault::ApplicationCollection.new(resource: applications_resource) }

  describe '#create' do
    let(:application_resource) { double('application_resource', name: name) }
    let(:name) { 'new_bitcoin_app' }
    let(:callback_url) { 'http://someapp.com/callback' }
    before(:each) {
      allow(application_collection.resource).to receive(:create).and_return(application_resource)
    }

    let(:application) { application_collection.create(name: name, callback_url: callback_url) }

    it 'delegates to the resource' do
      expect(application_collection.resource).to receive(:create)
      application
    end

    it 'returns an Application object' do
      expect(application).to be_a_kind_of(BitVault::Application)
    end

    it 'increases the application count' do
      expect { application }.to change(application_collection, :count).by(1)
    end
  end
end