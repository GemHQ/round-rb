require 'spec_helper'

describe BitVault::ApplicationCollection, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:user) { authed_client.user }

  describe '#initialize' do
    it 'sets the resource' do
      expect(user.applications.resource).to_not be_nil
      expect(user.applications.resource).to be_a_kind_of(Patchboard::Resource)
    end

    it 'instantiates the collection array' do
      BitVault::ApplicationCollection.any_instance.should_receive(:populate_data)
      user.applications
    end
  end

  describe '#populate_array' do
    it 'populates the array with Application objects' do
      user.applications.each do |name, app|
        expect(app).to be_a_kind_of(BitVault::Application)
      end
    end
  end

  describe '#create' do
    let(:application_resource) { double('application_resource') }
    let(:name) { 'new_bitcoin_app' }
    let(:callback_url) { 'http://someapp.com/callback' }
    before(:each) {
      allow(application_resource).to receive(:name) { name }
      user.applications.resource.stub(:create).and_return(application_resource)
    }

    let(:application) { user.applications.create(name: name, callback_url: callback_url) }

    it 'delegates to the resource' do
      user.applications.resource.should_receive(:create)
      application
    end

    it 'returns an Application object' do
      expect(application).to be_a_kind_of(BitVault::Application)
    end

    it 'increases the application count' do
      expect { application }.to change(user.applications, :count).by(1)
    end
  end
end