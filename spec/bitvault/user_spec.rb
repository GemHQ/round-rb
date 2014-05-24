require 'spec_helper'

describe BitVault::User, :vcr do
  let(:authed_client) { BitVault::Patchboard.authed_client(email: 'julian@bitvault.io', password: 'terrible_secret') }
  let(:resource) {

  }
  describe '#initialize' do
    context 'with a valid User resource' do
      it 'should set the resource' do

      end
    end

  end
end