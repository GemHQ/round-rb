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
      BitVault::ApplicationCollection.any_instance.should_receive(:populate_array)
      user.applications
    end
  end

  describe '#populate_array' do
    it 'populates the array with Application objects' do
      user.applications.each do |app|
        expect(app).to be_a_kind_of(BitVault::Application)
      end
    end
  end

  describe '#create' do
    it 'delegates to the resource' do
      user.applications.resource.stub(:create).and_return({})
      user.applications.resource.should_receive(:create)
      user.applications.create(name: 'bitcoin_app', callback_url:'http://someapp.com/callback')
    end
  end
end