require 'spec_helper'
require 'puppet/cloudpack'

describe Puppet::Face[:node, :current] do
  before :each do
    @options = {
      :login             => 'ubuntu',
      :keyfile           => 'file_on_disk.txt',
      :installer_payload => 'some.tar.gz',
      :installer_answers => 'some.answers',
      :node_group        => 'webserver'
    }
  end

  describe 'option validation' do
    before :each do
      Puppet::CloudPack.expects(:init).never
    end

    describe '(login)' do
      it 'should require a login' do
        @options.delete(:login)
        expect { subject.init('server', @options) }.to raise_error ArgumentError, /required/
      end
    end

    describe '(keyfile)' do
      it 'should require a keyfile' do
        @options.delete(:keyfile)
        expect { subject.init('server', @options) }.to raise_error ArgumentError, /required/
      end
    end

  end
end
