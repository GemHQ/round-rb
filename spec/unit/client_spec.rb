require 'spec_helper'

describe Round::Client do

  let(:client) { Round.client }
  let(:context) { Round::Client::Context.new }
  let(:patchboard) { double('patchboard', spawn: patchboard_client) }
  let(:patchboard_client) { double('patchboard_client', context: context, resources: resources) }
  let(:resources) { double('resources') }

  before(:each) {
    allow(Patchboard).to receive(:discover).and_return(patchboard)
  }

  describe '#resources' do
    it 'returns the patchboard client resources object' do
      expect(client.resources).to eql(resources)
    end
  end

  describe '#authenticate_application' do
    let(:instance_id) { 'randomid123' }
    let(:api_token) { 'randomtoken123' }
    let(:app_url) { 'http://api.gem.co/applications/application_key' }

    it 'authorizes the context with the correct credentials' do
      expect(context).to receive(:authorize).with(
        Round::Client::Context::Scheme::APPLICATION,
        api_token: api_token, instance_id: instance_id)

      client.authenticate_application app_url, api_token, instance_id
    end
    
  end

end