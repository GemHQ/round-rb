require 'spec_helper'

describe BitVault::Application, :vcr do
  let(:wallets_resource) { double('wallets_resource', list: []) }
  let(:context) { double('context', set_token: nil) }
  let(:application_resource) { double('application_resource', wallets: wallets_resource, context: context) }
  let(:application) { BitVault::Application.new(resource: application_resource) }

  describe 'delegate methods' do
    [:name, :callback_url, :api_token].each do |method|
      it "delegates #{method} to resource" do
        application.resource.should_receive(method)
        application.send(method)
      end
    end

    it 'delegates update to resource' do
      params = { name: 'other_app' }
      application.resource.should_receive(:update).with(params)
      application.update(params)
    end
  end

  describe '#wallets' do
    before(:each) {
      allow(application_resource).to receive(:api_token)
      allow(application_resource).to receive(:url)
    }

    it 'returns a WalletCollection' do
      expect(application.wallets).to be_a_kind_of(BitVault::WalletCollection)
    end

    it 'only fetches once' do
      application.resource.wallets.should_receive(:list).once
      application.wallets
      application.wallets
    end
  end
end