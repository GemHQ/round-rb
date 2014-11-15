require 'spec_helper'

describe Round::UserCollection do
  let(:email) { 'julian@bitvault.io' }
  let(:password) { 'terrible_secret' }
  let(:resource_mock) { double('user_resource') }
  let(:user_collection_resource) { double('user_collection_resource', create: resource_mock) }
  let(:user_collection) { Round::UserCollection.new(resource: user_collection_resource) }

  describe '#create' do
    context 'with a valid email and password' do
      let(:email) { 'julian@gem.co' }
      let(:passphrase) { 'terrible_secret' }
      let(:user) { user_collection.create(email, passphrase) }

      it 'delegates to the resource' do
        expect(user_collection.resource).to receive(:create)
        user
      end

      it 'returns a User model' do
        expect(user).to be_a_kind_of(Round::User)
      end
    end
  end

end