require 'spec_helper'

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

  describe '#developer_signature' do
    let(:privkey) { developer_private_key }
    let(:request_body) { '{"name":"name"}' }
    let(:date_string) { DateTime.new.strftime('%Y/%m/%d') }
    let(:content) { "#{request_body}-#{date_string}" }

    context 'with a valid key' do
      let(:signature) { context.developer_signature(request_body, privkey) }
      let(:decoded_signature) { Base64.urlsafe_decode64(signature) }

      it 'generates valid base64' do
        expect {
          decoded_signature
        }.to_not raise_error
      end

      it 'generates a valid signature' do
        key = OpenSSL::PKey::RSA.new privkey
        valid = key.verify(OpenSSL::Digest::SHA256.new, decoded_signature, content)
        expect(valid).to be(true)
      end
    end

    context 'with an invalid key' do
      let(:signature) { context.developer_signature(request_body, 'bogus_key') }

      it 'raises an error' do
        expect {
          signature
        }.to raise_error
      end
    end
  end
end