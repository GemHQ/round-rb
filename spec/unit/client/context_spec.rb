require 'spec_helper'
require 'date'

describe Round::Client::Context do
  let(:context) { Round::Client::Context.new }

  describe '#authorize' do
    context 'with a recognized auth scheme' do
      it 'succeeds' do 
        expect {
          context.authorize Round::Client::Context::Scheme::APPLICATION, 
            app_url: 'https://api.gem.com/applications/appurl',
            api_token: 'sometoken',
            instance_id: 'someinstance_id'
        }.to_not raise_error
        
      end
    end

    context 'with an unrecognized auth scheme' do
      it 'raises an error' do
        expect {
          context.authorize 'BogusAuthScheme', 
            app_url: 'https://api.gem.com/applications/appurl',
            api_token: 'sometoken',
            instance_id: 'someinstance_id'
        }.to raise_error
      end
    end
  end

  describe '#compile_params' do
    context 'when params is empty' do
      it 'raises error' do
        expect { context.compile_params({}) }.to raise_error(ArgumentError)
      end
    end

    context 'when params not empty' do
      it 'joins them into param string' do
        response = context.compile_params({a:1, b:2, c:3})
        expect(response).to eq 'a="1", b="2", c="3"'
      end
    end
  end

end
