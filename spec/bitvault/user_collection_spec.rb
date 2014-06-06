require 'spec_helper'

describe BitVault::UserCollection do
  let(:email) { 'julian@bitvault.io' }
  let(:password) { 'terrible_secret' }
  let(:user_collection_resource) { double('user_collection_resource') }
  let(:user_collection) { BitVault::UserCollection.new(resource: user_collection_resource) }

  describe '#create' do
    context 'with a valid email and password' do
      let(:params) { { email: 'julian@bitvault.io', password: 'terrible_secret' } }
      let(:user) { user_collection.create(params) }
      let(:resource_mock) { double('user_resource') }
      before(:each) {
        user_collection.resource.stub(:create).and_return(resource_mock)
      }

      it 'delegates to the resource' do
        user_collection.resource.should_receive(:create).with(params)
        user
      end

      it 'returns a User model' do
        expect(user).to be_a_kind_of(BitVault::User)
      end
    end

    context 'missing password' do
      it 'raises an error' do
        expect { user_collection.create(email: email) }.to raise_error(ArgumentError)
      end
    end

    context 'missing name' do
      it 'raises an error' do
        expect { user_collection.create(password: password) }.to raise_error(ArgumentError)
      end
    end
  end

end