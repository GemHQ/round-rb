require 'spec_helper'

describe Round::Base do
  let(:resource) { double('resource') }
  let(:base) { Round::Base.new(resource: resource) }

  describe '#initialize' do
    context 'with a resource' do
      it 'sets the resource' do
        expect(base.resource).to eql(resource)
      end
    end

    context 'with no resource' do
      it 'raises an error' do
        expect { Round::Base.new }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'delegated methods' do
    it 'delegates url to resource' do
      expect(resource).to receive(:url)
      base.url
    end
  end
end