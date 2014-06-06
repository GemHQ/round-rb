require 'spec_helper'

describe BitVault::User, :vcr do
  let(:applications_resource) { double('applications_resource', list: [])}
  let(:user_resource) { double('user_resource', applications: applications_resource) }
  let(:user) { BitVault::User.new(resource: user_resource) }

  describe 'delegate methods' do
    it 'delegates update to the resource' do
      user.resource.should_receive(:update).with({first_name: 'Julian'})
      user.update(first_name: 'Julian')
    end

    [:email, :first_name, :last_name].each do |method|
      it 'delegates email to the resource' do
        user.resource.should_receive(method)
        user.send(method)
      end
    end
  end

  describe '#applications' do
    it 'returns an ApplicationCollection' do
      expect(user.applications).to be_a_kind_of(BitVault::ApplicationCollection)
    end

    it 'only fetches once' do
      user.resource.applications.should_receive(:list).once
      user.applications
      user.applications
    end

    it 'fetches twice when refresh is passed' do
      user.resource.applications.should_receive(:list).twice
      user.applications
      user.applications(refresh: true)
    end
  end
end